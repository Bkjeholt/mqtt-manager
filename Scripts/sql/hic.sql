SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;


DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `calc_modified` ()  BEGIN
    DECLARE `NumberOfUpdatedCalculations` INT; 

	recalc_loop: LOOP
		BEGIN
			CALL `__calc_scan_modified`(); 

			SET `NumberOfUpdatedCalculations` =
				(SELECT COUNT(`calc_input`.`id`)
					FROM `calc_input`,`calc`
					WHERE (`calc_input`.`modified` = TRUE) AND
						  (`calc`.`active` = TRUE) AND
						  (`calc`.`id` = `calc_input`.`calc_id`)); 

			IF (`NumberOfUpdatedCalculations` = '0') THEN
				LEAVE recalc_loop; 
			END IF; 
		END; 
	END LOOP; 

END$$

CREATE DEFINER=`root`@`%` PROCEDURE `get_data` (IN `AgentName` VARCHAR(32), IN `NodeName` VARCHAR(32), IN `DeviceName` VARCHAR(32), IN `VariableName` VARCHAR(32), IN `DeltaTime` INT)  BEGIN
	DECLARE `TopicAddr` TEXT; 
	DECLARE `Body` TEXT; 
	DECLARE `VariableId` INT; 

	SET `VariableId` = `get_variable_id`(`AgentName`,`NodeName`,`DeviceName`,`VariableName`); 

	IF (`VariableId` >= '0') THEN
		IF (`VariableName` != '---') THEN
			SET `TopicAddr` = CONCAT(`AgentName`,'/',`NodeName`,'/',`DeviceName`,'/',`VariableName`); 
		ELSE
			SET `TopicAddr` = CONCAT(`AgentName`,'/',`NodeName`,'/',`DeviceName`); 
		END IF; 
        
        SET `Body` = `get_data_json`(`VariableId`, `DeltaTime`); 
        
        SELECT `TopicAddr` AS `topic_addr`,`Body` AS `message_body`; 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_calc` (IN `CalcName` VARCHAR(32), IN `CalcType` VARCHAR(16), IN `DstAgentName` VARCHAR(32), IN `DstNodeName` VARCHAR(32), IN `DstDeviceName` VARCHAR(32), IN `DstVariableName` VARCHAR(32))  BEGIN
	DECLARE `DstVariableId` INT DEFAULT '-1'; 

	SET `DstVariableId` = `get_variable_id`(`DstAgentName`,`DstNodeName`,`DstDeviceName`,`DstVariableName`); 
    
    IF (`DstVariableId` >= '0') THEN
		REPLACE INTO `calc`
			SET `name`        = `CalcName`,
				`type`        = `CalcType`,
				`variable_id` = `DstVariableId`,
				`active`      = FALSE; 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_calc_activate` (IN `CalcName` VARCHAR(32), IN `CalcActive` BOOL)  BEGIN
	DECLARE `CalcId` INT; 

	SET `CalcId` = (SELECT `id` FROM `calc` WHERE (`name` = `CalcName`) LIMIT 1); 

    IF (`CalcId` >= '0') THEN
		UPDATE `calc`
			SET `active` = `CalcActive`
			WHERE (`id` = `CalcId`); 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_calc_input` (IN `CalcName` VARCHAR(32), IN `SrcAgentName` VARCHAR(32), IN `SrcNodeName` VARCHAR(32), IN `SrcDeviceName` VARCHAR(32), IN `SrcVariableName` VARCHAR(32))  BEGIN
	DECLARE `SrcVariableId` INT DEFAULT '-1'; 
	DECLARE `CalcId` INT; 

	SET `CalcId` = (SELECT `id` FROM `calc` WHERE (`name` = `CalcName`) LIMIT 1); 

	SET `SrcVariableId` = `get_variable_id`(`SrcAgentName`,`SrcNodeName`,`SrcDeviceName`,`SrcVariableName`); 
    
    IF ((`SrcVariableId` >= '0') AND (`CalcId` >= '0')) THEN
		REPLACE INTO `calc_input`
			SET `calc_id`     = `CalcId`,
				`variable_id`   = `SrcVariableId`,
				`modified`      = FALSE,
				`modified_time` = '0',
				`data_trans_key`= '---'; 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_calc_param` (IN `CalcName` VARCHAR(32), IN `ParamName` VARCHAR(16), IN `ParamValue` VARCHAR(32))  BEGIN
	DECLARE `CalcId` INT; 

	SET `CalcId` = (SELECT `id` FROM `calc` WHERE (`name` = `CalcName`) LIMIT 1); 

    IF (`CalcId` >= '0') THEN
		REPLACE INTO `calc_param`
			SET `calc_id`     = `CalcId`,
				`name`        = `ParamName`,
				`value`      = `ParamValue`; 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_data` (IN `AgentName` VARCHAR(32), IN `NodeName` VARCHAR(32), IN `DeviceName` VARCHAR(32), IN `VariableName` VARCHAR(32), IN `Time` INT, IN `Data` TEXT)  BEGIN
	DECLARE `VariableId` INT DEFAULT '-1'; 
	DECLARE `DataTransactionKey` VARCHAR(32); 

	SET `VariableId` = `get_variable_id`(`AgentName`,`NodeName`,`DeviceName`,`VariableName`); 
    
    IF (`VariableId` >= '0') THEN
		SET `DataTransactionKey` = CONCAT('key-',`VariableId`,'-',`Time`); 

		CALL `__store_data`(`VariableId`, `Time`, `Data`,`DataTransactionKey`); 

		UPDATE `agent`
			SET `agent_last_access` = unix_timestamp()
            WHERE (`id` = `get_agent_id`(`AgentName`)); 

		CALL `calc_modified`(); 

    END IF; 
    
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_data_transaction_key` (IN `AgentName` VARCHAR(32), IN `NodeName` VARCHAR(32), IN `DeviceName` VARCHAR(32), IN `VariableName` VARCHAR(32), IN `Time` INT, IN `Data` TEXT, IN `DataTransactionKey` VARCHAR(32))  BEGIN
	DECLARE `VariableId` INT DEFAULT '-1'; 

	SET `VariableId` = `get_variable_id`(`AgentName`,`NodeName`,`DeviceName`,`VariableName`); 
    
    IF (`VariableId` >= '0') THEN

		CALL `__store_data`(`VariableId`, `Time`, `Data`,`DataTransactionKey`); 

		UPDATE `agent`
			SET `agent_last_access` = unix_timestamp()
            WHERE (`id` = `get_agent_id`(`AgentName`)); 
    END IF; 
    
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_info_agent` (IN `AgentName` VARCHAR(32), IN `AgentVer` VARCHAR(32))  BEGIN
	DECLARE `AgentId` INT; 

	SET `AgentId` = `get_agent_id`(`AgentName`); 

	IF (`AgentId` < '0') THEN
		INSERT INTO `agent`(`name`,`ver`,`agent_last_access`)
			VALUES
				(`AgentName`,`AgentVer`,UNIX_TIMESTAMP()); 
	ELSE
		UPDATE `agent`
			SET
				`ver` = `AgentVer`,
				`agent_last_access` = UNIX_TIMESTAMP()
			WHERE `id` = `AgentId`; 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_info_device` (IN `AgentName` VARCHAR(32), IN `NodeName` VARCHAR(32), IN `DeviceName` VARCHAR(32))  BEGIN
	DECLARE `NodeId` INT; 
	DECLARE `DeviceId` INT; 

	DECLARE `NotFound` INT DEFAULT FALSE; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `NotFound` = TRUE; 

	SET `NodeId` = `get_node_id`(`AgentName`,`NodeName`); 

	IF (`NodeId` >= '0') THEN
		SET `DeviceId` = `get_device_id`(`AgentName`,`NodeName`,`DeviceName`); 

		IF (`DeviceId` < '0') THEN
			INSERT INTO `device`(`name`,`node_id`)
				VALUES
					(`DeviceName`,`NodeId`); 
			SET `DeviceId` = LAST_INSERT_ID(); 
        END IF; 
	ELSE
		CALL `store_info_node`(`AgentName`, `NodeName`, '---', 'undef'); 

		INSERT INTO `data_text`(`variable_id`,`time`,`error_code`,`error_severity`,`data`)
			VALUES
				('-1',UNIX_TIMESTAMP(),'1002','warning',
				 CONCAT('New device -> Unexpected Node created  -> ',
						`AgentName`,'/',`NodeName`,'/',`DeviceName`)); 


		INSERT INTO `device`(`name`,`node_id`)
			VALUES
				(`DeviceName`,`get_node_id`(`AgentName`,`NodeName`)); 

	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_info_node` (IN `AgentName` VARCHAR(32), IN `NodeName` VARCHAR(32), IN `NodeVer` VARCHAR(16), IN `NodeType` VARCHAR(16))  BEGIN
	DECLARE `NodeId` INT; 
	DECLARE `AgentId` INT; 

	SET `AgentId` = `get_agent_id`(`AgentName`); 

	IF (`AgentId` >= '0') THEN
		SET `NodeId` = `get_node_id`(`AgentName`,`NodeName`); 

		IF (`NodeId` < '0') THEN
			INSERT INTO `node`(`name`,`ver`,`type`,`agent_id`)
				VALUES
					(`NodeName`,`NodeVer`,`NodeType`,`AgentId`); 
		ELSE
			UPDATE `node`
				SET
					`ver` = `NodeVer`,
					`type` = `NodeType`
				WHERE `id` = `NodeId`; 
		END IF; 
	ELSE
		CALL `store_info_agent`(`AgentName`, '---'); 

		INSERT INTO `data_text`(`variable_id`,`time`,`data`)
			VALUES
				('-1',UNIX_TIMESTAMP(),
				 CONCAT('Warning: new node -> Unexpected Agent created  -> ',
						`AgentName`,'/',`NodeName`)); 

		INSERT INTO `node`(`name`,`ver`,`type`,`agent_id`)
			VALUES
				(`NodeName`,`NodeVer`,`NodeType`,`get_agent_id`(`AgentName`)); 
	END IF; 

END$$

CREATE DEFINER=`root`@`%` PROCEDURE `store_info_variable` (IN `AgentName` VARCHAR(32), IN `NodeName` VARCHAR(32), IN `DeviceName` VARCHAR(32), IN `VariableName` VARCHAR(32), IN `DataType` VARCHAR(32), IN `DeviceType` VARCHAR(32), IN `WrapAround` INT, IN `DataCoef` FLOAT, IN `DataOffset` FLOAT, IN `OutputVar` TINYINT)  BEGIN
	DECLARE `DeviceId` INT; 
	DECLARE `VariableId` INT; 
	DECLARE `Primary` TINYINT(1) DEFAULT TRUE; 
	DECLARE `CleanDAT` VARCHAR(32); 
	DECLARE `CleanDET` VARCHAR(32); 
	DECLARE `CleanWrapAround` INT; 

	CASE (`DataType`) 
		WHEN 'bool' THEN SET `CleanDAT` = 'bool'; 
		WHEN 'int' THEN SET `CleanDAT` = 'int'; 
		WHEN 'float' THEN SET `CleanDAT` = 'float'; 
		ELSE SET `CleanDAT` = 'text'; 
	END CASE; 

	CASE (`DeviceType`) 
		WHEN 'semistatic' THEN SET `CleanDET` = 'semistatic'; 
		WHEN 'static' THEN SET `CleanDET` = 'static'; 
		ELSE SET `CleanDET` = 'dynamic'; 
	END CASE; 

	IF (`WrapAround` = '0') THEN
		SET `CleanWrapAround` = NULL; 
	ELSE
		SET `CleanWrapAround` = `WrapAround`; 
	END IF; 

	SET `VariableId` = `get_variable_id`(`AgentName`,`NodeName`,`DeviceName`,`VariableName`); 

	IF (`VariableId` >= '0') THEN
		UPDATE `variable`
			SET
				`data_type` = `DataType`,
				`device_type` = `DeviceType`,
				`wraparound` = `WrapAround`,
				`data_coef` = `DataCoef`,
				`data_offset` = `DataOffset`,
				`output` = `OutputVar`
			WHERE `id` = `VariableId`; 
	ELSE
		SET `Primary` = (`VariableName` = '---'); 
		SET `DeviceId` = `get_device_id`(`AgentName`,`NodeName`,`DeviceName`); 

		IF (`DeviceId` >= '0') THEN
			INSERT INTO `variable`(`name`,`primary`,`output`,`device_id`,
								   `data_type`,`device_type`,`wraparound`,`wraparound_offset`,`data_coef`,`data_offset`)
				VALUES
					(`VariableName`,`Primary`,`OutputVar`,`DeviceId`,
					 `DataType`,`DeviceType`,`WrapAround`,'0',`DataCoef`,`DataOffset`); 
			SET `VariableId` = LAST_INSERT_ID(); 
		ELSE
			CALL `store_info_device`(`AgentName`,`NodeName`,`DeviceName`); 

			INSERT INTO `data_text`(`variable_id`,`time`,`data`)
				VALUES
					('-1',UNIX_TIMESTAMP(),
					CONCAT('Warning: new variable -> Unexpected Device created  -> ',
						   `AgentName`,'/',`NodeName`,'/',`DeviceName`,'/',`VariableName`)); 

			INSERT INTO `variable`(`name`,`primary`,`output`,`device_id`,
								   `data_type`,`device_type`,`wraparound`,`wraparound_offset`,`data_coef`,`data_offset`)
				VALUES
					(`VariableName`,FALSE,`OutputVar`,`get_device_id`(`AgentName`,`NodeName`,`DeviceName`),
					 `DataType`,`DeviceType`,`WrapAround`,'0',`DataCoef`,`DataOffset`); 
			SET `VariableId` = LAST_INSERT_ID(); 

		END IF; 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_avg` (IN `CalcId` INT, IN `DataTransitionKey` VARCHAR(32))  BEGIN
	DECLARE `NumberOfParams` INT; 
	DECLARE `NumberOfDatas` INT DEFAULT '0'; 

	DECLARE `CalcInterval` INT; 
	DECLARE `FromTime` INT; 
	DECLARE `ToTime` INT; 

	DECLARE `CalcAverageValue` FLOAT; 

	SELECT COUNT(*)
		INTO `NumberOfParams`
		FROM `calc_param`
		WHERE (`calc_id` = `CalcId`) AND
			  (`name` = 'time'); 
	INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						('-1', UNIX_TIMESTAMP(),CONCAT('Warning: __calc_avg (',`NumberOfDatas`,') Data ->',`NumberOfParams`)); 

	IF (`NumberOfParams` > '0') THEN
		SET `ToTime` = (SELECT `modified_time` 
									FROM `calc_input` 
									WHERE (`calc_id` = `CalcId`)
									ORDER BY `id` DESC
									LIMIT 1); 

		SET `CalcInterval` = (SELECT `value` 
									FROM `calc_param` 
									WHERE (`calc_id` = `CalcId`) AND
										  (`name` = 'time')
									ORDER BY `id` DESC
									LIMIT 1); 
		
		SET `FromTime` = `ToTime` - `CalcInterval`; 

		SET `NumberOfDatas` = (SELECT COUNT(`data_float`.`id`) 
								FROM `data_float` ,`calc_input`
								WHERE (`calc_input`.`calc_id` = `CalcId`) AND
									  (`data_float`.`variable_id` = `calc_input`.`variable_id`) AND
									  (`data_float`.`time` > `FromTime`) AND
									  (`data_float`.`time` <= `ToTime`) ); 

		IF (`NumberOfDatas` > '0') THEN
			SET `CalcAverageValue` = (SELECT AVG(`data_float`.`data`) 
										FROM `data_float`, `calc_input`
										WHERE (`calc_input`.`calc_id` = `CalcId`) AND
											  (`calc_input`.`variable_id` = `data_float`.`variable_id`) AND
											  (`data_float`.`time` > `FromTime`) AND
											  (`data_float`.`time` <= `ToTime`)); 

			CALL `__store_data`((SELECT `variable_id` 
									FROM `calc` 
									WHERE (`id` = `CalcId`) 
									LIMIT 1), 
								`ToTime`,
								`CalcAverageValue`, 
								`DataTransitionKey`); 
		END IF; 
	END IF; 

END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_avg1` (IN `CalcId` INT, IN `DataTransitionKey` VARCHAR(32))  BEGIN
	DECLARE `NumberOfParams` INT; 
	DECLARE `NumberOfDatas` INT DEFAULT '0'; 

	DECLARE `CalcInterval` INT; 
	DECLARE `FromTime` INT; 
	DECLARE `ToTime` INT; 

	DECLARE `CalcAverageValue` FLOAT; 

	SELECT COUNT(*)
		INTO `NumberOfParams`
		FROM `calc_param`
		WHERE (`calc_id` = `CalcId`) AND
			  (`name` = 'time'); 

	IF (`NumberOfParams` > '0') THEN
		SET `ToTime` = (SELECT `modified_time` 
									FROM `calc_input` 
									WHERE (`calc_id` = `CalcId`)
									ORDER BY `id` DESC
									LIMIT 1); 

		SET `CalcInterval` = (SELECT `value` 
									FROM `calc_param` 
									WHERE (`calc_id` = `CalcId`) AND
										  (`name` = 'time')
									ORDER BY `id` DESC
									LIMIT 1); 
		
		SET `FromTime` = `ToTime` - `CalcInterval`; 

# 		SET `NumberOfDatas` = (SELECT COUNT(`data_float`.`id`) # 								FROM `data_float` ,`calc_param`# 								WHERE (`calc_input`.`calc_id` = `CalcId`) AND# 									  (`data_float`.`variable_id` = `calc_input`.`variable_id`) AND# 									  (`data_float`.`time` > `FromTime`) AND# 									  (`data_float`.`time` <= `ToTime`) ); 
		INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						('-1', UNIX_TIMESTAMP(),CONCAT('Warning: __calc_avg (',`NumberOfDatas`,') Data ->',`NumberOfParams`)); 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_linear` (IN `CalcId` INT, IN `DataTransitionKey` VARCHAR(32))  BEGIN
-- -- 	Calculate to allocation value for what's defined in the calculations table. -- 	This is normally a conversion between a device and a sensor unit.
	DECLARE `InputDataValue` TEXT; 
	DECLARE `InputDataType` VARCHAR(16); 
	DECLARE `InputDataTime` INT; 
	DECLARE `InputDataExist`BOOL DEFAULT FALSE; 

	DECLARE `NumberOfParams` INT; 

	DECLARE `CalcCoef` FLOAT DEFAULT '1.0'; 
	DECLARE `CalcOffset` FLOAT DEFAULT '0'; 

	DECLARE `VariableId` INT; 
	DECLARE `CalcInputId` INT; 

    	DECLARE `CalcParam` VARCHAR(16); 
    	DECLARE `CalcParamValue` FLOAT; 

-- 	Get input device data	SELECT `variable_id`, `id` 
		INTO `VariableId`,`CalcInputId` 
		FROM `calc_input` 
		WHERE (`calc_id` = `CalcId`) 
		LIMIT 1; 

	UPDATE `calc_input`
		SET `modified` = FALSE
		WHERE (`id` = `CalcInputId`); 

	CALL `__get_data_test`(`VariableId`, 
					  '0',
					  `InputDataValue`,
					  `InputDataTime`,
					  `InputDataType`,
					  `InputDataExist` ); 

INSERT INTO `data_text`(`variable_id`,`time`,`data`)
	VALUES
		('-1',UNIX_TIMESTAMP(),
		 CONCAT('Observation: _calc_linear (input data/time/type/existans)-> ',
# 				`InputDataValue`,'/',`InputDataTime`,'/',`InputDataType`,'/',`InputDataExist`)); 

	IF (`InputDataExist`) THEN

--  	Get parameters from the calculations_params table used for the calculation 
		SELECT COUNT(*)
			INTO `NumberOfParams`
			FROM `calc_param`
			WHERE (`calc_id` = `CalcId`)
			LIMIT 1; 

		WHILE (`NumberOfParams` > '0') DO
			SET `NumberOfParams` = `NumberOfParams` - '1'; 

			SELECT `name`,`value`
				INTO `CalcParam`,`CalcParamValue`
				FROM `calc_param`
				WHERE (`calc_id` = `CalcId`) 
				LIMIT `NumberOfParams`,1; 

			CASE (`CalcParam`)
				WHEN 'coef'         THEN SET `CalcCoef`        = `CalcParamValue`; 
				WHEN 'offset'       THEN SET `CalcOffset`      = `CalcParamValue`; 
			END CASE; 
		END WHILE; 



		CASE (`InputDataType`)
			WHEN 'float' THEN
				BEGIN
					DECLARE `Data` FLOAT; 
					DECLARE `VariableId` INT; 
# 					DECLARE `DataTransitionKey` VARCHAR(32); 
					SET `Data` = `InputDataValue`; 

# 					INSERT INTO `data_text`(`variable_id`,`time`,`data`)# 						VALUES# 							('-1',UNIX_TIMESTAMP(),# 							 CONCAT('Observation: _calc_linear (Input data/time/type/existans/Coef/Offset)-> ',# 							 `Data`,'/',`InputDataTime`,'/',`InputDataType`,'/',`InputDataExist`,'/',`CalcCoef`,'/',`CalcOffset`)); 
					SET `VariableId` = (SELECT `variable_id` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1); 
# 					SET `DataTransitionKey` = (SELECT `data_trans_key` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1); 
					CALL `__store_data`(`VariableId`, 
 									    `InputDataTime`,
 										(`Data`*`CalcCoef` + `CalcOffset`), 
 										`DataTransitionKey`); 

				END; 
			WHEN 'int' THEN
				BEGIN
					DECLARE `Data` INT; 

					SET `Data` = `InputDataValue`; 
					CALL `__store_data`((SELECT `variable_id` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1), 
									    `InputDataTime`,
										(`Data`*`CalcCoef` + `CalcOffset`), 
										(SELECT `data_trans_key` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1)); 
				END; 
			WHEN 'text' THEN
				BEGIN
					DECLARE `Data` TEXT;
                    
					SET `Data` = `InputDataValue`; 
					CALL `__store_data`((SELECT `variable_id` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1), 
									    `InputDataTime`,
										`Data`, 
										(SELECT `data_trans_key` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1)); 					
				END;
			ELSE
				INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						('-1',`DataTime`,
						 CONCAT('Error: Unsupported InputDataType (CalcId/CalcName/InputVariableId/InputVariableType)-> ',
						 `CalcId`,'/',`CalcName`,'/',(SELECT `variable_id` FROM `calc_input` WHERE (`calc_id` = `CalcId`) LIMIT 1),'/',`InputDataType`)); 

		END CASE; 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_min` (IN `CalcId` INT, IN `DataTransitionKey` VARCHAR(32))  BEGIN
	DECLARE `ResultDataValue` FLOAT DEFAULT '0'; 
	DECLARE `ResultDataTime` INT DEFAULT '0'; 
	DECLARE `FirstData` BOOL DEFAULT TRUE; 

	DECLARE `CalcInputId` INT; 
	DECLARE `VariableId` INT; 

	DECLARE `DataValue` FLOAT; 
	DECLARE `DataTime` INT; 
	DECLARE `DataType` VARCHAR(16); 
	DECLARE `DataExist` BOOL; 

	DECLARE `Done` INT DEFAULT FALSE; 
    DECLARE `Cursor` CURSOR FOR
		SELECT  `id`,
				`variable_id` 
			FROM `calc_input`
            WHERE
				(`calc_id` = `CalcId`); 

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

	OPEN `Cursor`; 

	read_input_data_loop: LOOP
		FETCH `Cursor`
			INTO `CalcInputId`,`VariableId`; 

		IF (`Done`) THEN
			LEAVE read_input_data_loop; 
		END IF; 
	
		UPDATE `calc_input` 
			SET `modified` = FALSE
			WHERE (`id` = `CalcInputId`); 

		CALL `db`.`__get_data`(`VariableId`, '0', 
							    `DataValue`, `DataTime`, `DataType`, `DataExist`); 
		IF ((`ResultDataValue` > `DataValue`) OR (`FirstData`)) THEN
			SET `ResultDataValue` = `DataValue`; 
			SET `FirstData` = FALSE; 
		END IF; 

		IF (`ResultDataTime` < `DataTime`) THEN
			SET `ResultDataTime` = `DataTime`; 
		END IF; 


	END LOOP; 

	CALL `__store_data`((SELECT `variable_id` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1), 
						`ResultDataTime`,
						`ResultDataValue`, 
						`DataTransitionKey` ); 

END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_power` (IN `CalcId` INT, IN `DataTransitionKey` VARCHAR(32))  BEGIN
	DECLARE `Input_1_DataValue` TEXT; 
	DECLARE `Input_1_DataType` VARCHAR(16); 
	DECLARE `Input_1_DataTime` INT; 
	DECLARE `Input_1_DataExist`BOOL DEFAULT FALSE; 
	DECLARE `Input_2_DataValue` TEXT; 
	DECLARE `Input_2_DataType` VARCHAR(16); 
	DECLARE `Input_2_DataTime` INT; 
	DECLARE `Input_2_DataExist`BOOL DEFAULT FALSE; 

	DECLARE `CalcTime` FLOAT DEFAULT '600'; 
	DECLARE `CalcAdjust` FLOAT DEFAULT '1'; 

	DECLARE `VariableId` INT; 
	DECLARE `CalcInputId` INT; 

	get_parameter_information: BEGIN
		DECLARE `NumberOfParams` INT; 
		DECLARE `CalcParam` VARCHAR(16); 
		DECLARE `CalcParamValue` FLOAT; 

		SELECT COUNT(*)
			INTO `NumberOfParams`
			FROM `calc_param`
			WHERE (`calc_id` = `CalcId`)
			LIMIT 1; 

		WHILE (`NumberOfParams` > '0') DO
			SET `NumberOfParams` = `NumberOfParams` - '1'; 

			SELECT `name`,`value`
				INTO `CalcParam`,`CalcParamValue`
				FROM `calc_param`
				WHERE (`calc_id` = `CalcId`) 
				LIMIT `NumberOfParams`,1; 

			CASE (`CalcParam`)
				WHEN 'time'         THEN SET `CalcTime`        = `CalcParamValue`; 
				WHEN 'adjust'       THEN SET `CalcAdjust`      = `CalcParamValue`; 
			END CASE; 
		END WHILE; 
        
        INSERT INTO `data_text`(`variable_id`,`time`,`data`)
			VALUES
				('-1',UNIX_TIMESTAMP(),
				CONCAT('Observation: __calc_power 1 (calc-id/Delta-time)-> ',
			    `CalcId`,'/',`CalcTime`,'/',`CalcAdjust`)); 

	END get_parameter_information; 

-- 	Get input device data	SELECT `variable_id`, `id` 
		INTO `VariableId`,`CalcInputId` 
		FROM `calc_input` 
		WHERE (`calc_id` = `CalcId`) 
		LIMIT 1; 

	INSERT INTO `data_text`(`variable_id`,`time`,`data`)
		VALUES
			('-1',UNIX_TIMESTAMP(),
			 CONCAT('Observation: __calc_power 2 (var-id/CalcInputId)-> ',
			        `VariableId`,'/',`CalcInputId`)); 

	UPDATE `calc_input`
		SET `modified` = FALSE
		WHERE (`id` = `CalcInputId`); 

	CALL `__get_data_test`(`VariableId`, 
					  `CalcTime`,
					  `Input_1_DataValue`,
					  `Input_1_DataTime`,
					  `Input_1_DataType`,
					  `Input_1_DataExist` ); 
	CALL `__get_data_test`(`VariableId`, 
					  '0',
					  `Input_2_DataValue`,
					  `Input_2_DataTime`,
					  `Input_2_DataType`,
					  `Input_2_DataExist` ); 

	IF ((`Input_2_DataExist`) AND (`Input_2_DataTime` > `Input_1_DataTime`))THEN
		CALL `__store_data`((SELECT `variable_id` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1), 
							`Input_2_DataTime`,
							((`Input_2_DataValue`-`Input_1_DataValue`)/(`Input_2_DataTime`-`Input_1_DataTime`)*`CalcAdjust`*'3600' ), 
							(SELECT `data_trans_key` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1)); 

	END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_scan_modified` ()  BEGIN
	DECLARE `CalcId` INT; 
    DECLARE `VariableId` INT; 
    DECLARE `CalcName` VARCHAR(32); 
    DECLARE `CalcType` VARCHAR(16); 
	DECLARE `CalcInputModified` BOOL; 
    DECLARE `CalcTransactionKey` VARCHAR(32); 

	DECLARE `Done` INT DEFAULT FALSE; 
    DECLARE `Cursor` CURSOR FOR
		SELECT `calc`.`id`,
				`calc`.`name`,
				`calc`.`type`,
				`calc`.`variable_id`,
				`calc_input`.`data_trans_key` 
			FROM `calc`,`calc_input`
            WHERE
				(`calc_input`.`modified` = TRUE) AND
				(`calc`.`id` = `calc_input`.`calc_id`) AND
				(`calc`.`active` = TRUE)
			ORDER BY `calc_input`.`modified_time` ASC; 

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

	OPEN `Cursor`; 
    
	read_loop: LOOP
		FETCH `Cursor`
			INTO `CalcId`,`CalcName`,`CalcType`,`VariableId`,`CalcTransactionKey`; 
    
		IF (`Done`) THEN
			LEAVE read_loop; 
		END IF; 

# 		UPDATE `calc` # 			SET `modified` = FALSE# 			WHERE (`id` = `CalcId`); 
		CASE (`CalcType`)
			WHEN 'linear' THEN
				BEGIN
					CALL `__calc_linear`(`CalcId`,`CalcTransactionKey`); 
				END; 
			WHEN 'min' THEN
				BEGIN
					CALL `__calc_min`(`CalcId`,`CalcTransactionKey`); 
				END; 
			WHEN 'power' THEN
				BEGIN
					CALL `__calc_power`(`CalcId`,`CalcTransactionKey`); 
				END; 
			WHEN 'avg' THEN
				BEGIN
					CALL `__calc_avg`(`CalcId`,`CalcTransactionKey`); 
				END; 
			ELSE
				BEGIN
					INSERT INTO `data_text`(`variable_id`,`time`,`data`)
						VALUES
							('-1',UNIX_TIMESTAMP(),
							 CONCAT('Error: Unsupported CalcType (CalcId/CalcName/CalcType)-> ',
						 `CalcId`,'/',`CalcName`,'/',`CalcType`)); 
				END; 
		END CASE; 
    END LOOP; 


END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__get_data` (IN `VariableId` INT, IN `DeltaTime` INT, OUT `DataValue` TEXT, OUT `DataTime` INT, OUT `DataType` VARCHAR(16), OUT `DataExist` BOOL)  BEGIN
	DECLARE `DeviceNotFound` BOOLEAN DEFAULT FALSE; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `DeviceNotFound` = TRUE; 

INSERT INTO `data_text`(`variable_id`,`time`,`data`)
	VALUES
		('-1',UNIX_TIMESTAMP(),
		 CONCAT('Observation: _get_data 1 (var-id/Delta-time)-> ',
			    `VariableId`,'/',`DeltaTime`)); 


    SET `DataValue` = '0'; 
    IF (`VariableId` >= '0') THEN
		SET `DataType` = (SELECT `data_type`
							FROM `variable`
                            WHERE (`id` = `VariableId`)); 
INSERT INTO `data_text`(`variable_id`,`time`,`data`)
	VALUES
		('-1',UNIX_TIMESTAMP(),
		 CONCAT('Observation: _get_data (input data/time/type/existans)-> ',
			    `DataType`)); 
                           
		CASE `DataType`
			WHEN 'bool' THEN
				SELECT `data`,`time` 
					INTO `DataValue`,`DataTime`
                    FROM `data_bool`
					WHERE 
						(`variable_id` = `VariableId`) AND 
                        (`time` <= (UNIX_TIMESTAMP() - `DeltaTime`))
					ORDER BY `time` DESC
					LIMIT 1; 
            WHEN 'int' THEN
				SELECT `data`,`time` 
					INTO `DataValue`,`DataTime`
                    FROM `data_int`
					WHERE 
						(`variable_id` = `VariableId`) AND 
                        (`time` <= (UNIX_TIMESTAMP() - `DeltaTime`))
					ORDER BY `time` DESC
					LIMIT 1; 
            WHEN 'float' THEN
				SELECT `data`,`time` 
					INTO `DataValue`,`DataTime`
                    FROM `data_float`
					WHERE 
						(`variable_id` = `VariableId`) AND 
                        (`time` <= (UNIX_TIMESTAMP() - `DeltaTime`))
					ORDER BY `time` DESC
					LIMIT 1; 
            ELSE
				SELECT `data`,`time` 
					INTO `DataValue`,`DataTime`
                    FROM `data_text`
					WHERE 
						(`variable_id` = `VariableId`) AND 
                        (`time` <= (UNIX_TIMESTAMP() - `DeltaTime`))
					ORDER BY `time` DESC
					LIMIT 1; 
		END CASE; 
  
		IF ((`DeviceNotFound`) OR (`DataValue` = '')) THEN
			SET `DataExist` = FALSE; 
		ELSE
			SET `DataExist` = TRUE; 
		END IF; 
    END IF; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__get_data_test` (IN `VariableId` INT, IN `DeltaTime` INT, OUT `DataValue` TEXT, OUT `DataTime` INT, OUT `DataType` VARCHAR(16), OUT `DataExist` BOOL)  BEGIN
	DECLARE `RecordedTime` INT; 
	DECLARE `NumberOfDataRecords` INT; 

INSERT INTO `data_text`(`variable_id`,`time`,`data`)
	VALUES
		('-1',UNIX_TIMESTAMP(),
		 CONCAT('Observation: _get_data 1 (var-id/Delta-time)-> ',
			    `VariableId`,'/',`DeltaTime`)); 

    SET `DataValue` = 'Undefined'; 
    SET `DataTime`  = UNIX_TIMESTAMP(); 
    SET `DataType`  = 'text'; 
    SET `DataExist` = false; 

	SET `RecordedTime` = UNIX_TIMESTAMP() - `DeltaTime`; 
	SET `DataType` = (SELECT `data_type`
							FROM `variable`
                            WHERE (`id` = `VariableId`)); 

	CASE (`DataType`) 
		WHEN 'bool' THEN
			SET `DataExist` = ((SELECT COUNT(*)	
									FROM `data_bool`
									WHERE (`variable_id` = `VariableId`) AND
										  (`time` <= `RecordedTime`)
									LIMIT 1) > '0'); 

			IF (`DataExist`) THEN
				SELECT `time`,`data`	
					INTO `DataTime`,`DataValue`
					FROM `data_bool`
					WHERE (`variable_id` = `VariableId`) AND
						  (`time` <= `RecordedTime`)
					ORDER BY `time` DESC
					LIMIT 1; 
			END IF; 
		WHEN 'float' THEN
			SET `DataExist` = ((SELECT COUNT(*)	
									FROM `data_float`
									WHERE (`variable_id` = `VariableId`) AND
										  (`time` <= `RecordedTime`)
									LIMIT 1) > '0'); 

			IF (`DataExist`) THEN
				SELECT `time`,`data`	
					INTO `DataTime`,`DataValue`
					FROM `data_float`
					WHERE (`variable_id` = `VariableId`) AND
						  (`time` <= `RecordedTime`)
					ORDER BY `time` DESC
					LIMIT 1; 
			END IF; 
		WHEN 'int' THEN
			SET `DataExist` = ((SELECT COUNT(*)	
									FROM `data_int`
									WHERE (`variable_id` = `VariableId`) AND
										  (`time` <= `RecordedTime`)
									LIMIT 1) > '0'); 

			IF (`DataExist`) THEN
				SELECT `time`,`data`	
					INTO `DataTime`,`DataValue`
					FROM `data_int`
					WHERE (`variable_id` = `VariableId`) AND
						  (`time` <= `RecordedTime`)
					ORDER BY `time` DESC
					LIMIT 1; 
			END IF; 
		WHEN 'text' THEN
			SET `DataExist` = ((SELECT COUNT(*)	
									FROM `data_text`
									WHERE (`variable_id` = `VariableId`) AND
										  (`time` <= `RecordedTime`)
									LIMIT 1) > '0'); 

			IF (`DataExist`) THEN
				SELECT `time`,`data`	
					INTO `DataTime`,`DataValue`
					FROM `data_text`
					WHERE (`variable_id` = `VariableId`) AND
						  (`time` <= `RecordedTime`)
					ORDER BY `time` DESC
					LIMIT 1; 
			END IF; 
		ELSE
			INSERT INTO `data_text`(`variable_id`,`time`,`data`)
				VALUES
					('-1',UNIX_TIMESTAMP(),
					 CONCAT('Error: Unsupported datatype (function/var-id/Datatype)-> ',
					        '_get_data/',`VariableId`,'/',`DataType`)); 
	END CASE; 
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `__store_data` (IN `VariableId` INT, IN `Time` INT, IN `Data` TEXT, IN `DataTransactionKey` VARCHAR(32))  BEGIN
	DECLARE `DataType` ENUM('bool','int','float','text'); 
	DECLARE `DataCoef` FLOAT DEFAULT '1.0'; 
	DECLARE `DataOffset` FLOAT DEFAULT '0'; 
	DECLARE `DeviceType` ENUM ('dynamic','semistatic','static'); 
	DECLARE `WrapAround` INT; 
	DECLARE `WrapAroundOffset` INT; 
	DECLARE `PublishData` BOOL DEFAULT FALSE; 

	DECLARE `NotFound` INT DEFAULT FALSE; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `NotFound` = TRUE; 

	SELECT 
			`data_type` AS `DataType`,
			`device_type` AS `DeviceType`,
            `wraparound` AS `WrapAround`,
            `wraparound_offset` AS `WrapAroundOffset`,
            `data_coef` AS `DataCoef`,
            `data_offset` AS `DataOffset`,
			`output` AS `PublishData`
	INTO `DataType`,`DeviceType`,`WrapAround`,`WrapAroundOffset`,`DataCoef`,`DataOffset`,`PublishData`
	FROM `variable`
	WHERE (`id` = `VariableId`)
	LIMIT 1 ; 

	CASE `DataType`
		WHEN 'bool' THEN
			REPLACE INTO `data_bool`
				SET	`variable_id` = `VariableId`,
					`time` = `Time`,
                    `data` = `Data`; 
# 				INSERT INTO `data_bool`(`variable_id`,`time`,`data`)# 					VALUES# 						(`VariableId`, `Time`,`Data`); 		WHEN 'int' THEN
			BEGIN
				DECLARE `LatestData` INT; 
				DECLARE `CurrentData` INT; 
                
				IF ((`WrapAround` != NULL) AND (`WrapAround` > '0')) THEN
					SET `CurrentData` = `Data` + `WrapAroundOffset`; 
					SET `LatestData` = `get_latest_variable_data`(`VariableId`); 

					IF (`CurrentData` < `LatestData`) THEN
						SET `CurrentData` = `CurrentData` + `WrapAround`; 
                        
						UPDATE `variable`
							SET `wraparound_offset` = `wraparound_offset` + `wraparound`
							WHERE (`id` = `VariableId`); 
					END IF; 
                ELSE
					SET `CurrentData` = `Data`;    
				END IF; 

			REPLACE INTO `data_int`
				SET	`variable_id` = `VariableId`,
					`time` = `Time`,
                    `data` = `CurrentData`; 
			END; 
		WHEN 'float' THEN
#			INSERT INTO `hic`.`data_float`(`variable_id`,`time`,`data`)# 				VALUES# 					(`VariableId`,`Time`,(`Data`*`DataCoef`+`DataOffset`)); # 			REPLACE INTO `data_float`
				SET	`variable_id` = `VariableId`,
					`time` = `Time`,
                  `data` = (`Data`*`DataCoef`+`DataOffset`); 
		WHEN 'text' THEN
				INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						(`VariableId`, `Time`,`Data`); 
		ELSE
				INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						(`VariableId`, `Time`,CONCAT('Warning: Non-supported datatype (',`DataType`,') Data ->',`Data`)); 
	END CASE; 
    
	update_calc_mod_info: BEGIN
# 		UPDATE `calc`,`calc_input`# 			SET `calc`.`modified` = TRUE,# 				`calc`.`modified_time` = `Time`,# 				`calc`.`data_trans_key` = `DataTransactionKey`# 			WHERE (`calc`.`id` = `calc_input`.`calc_id`) AND# 				  (`calc_input`.`variable_id` = `VariableId`) AND# 				  ((`calc`.`modified` = FALSE) OR# 				   (`calc`.`modified_time` < `Time`));				UPDATE `calc_input`
			SET `modified` = TRUE,
				`modified_time` = `Time`,
				`data_trans_key` = `DataTransactionKey`
			WHERE (`variable_id` = `VariableId`) AND
				  ((`modified` = FALSE) OR
				   (`modified_time` < `Time`)); 
	END; 

	IF (`PublishData`) THEN
		REPLACE INTO `data_publish`
			SET `variable_id` = `VariableId`,
				`time` = `Time`,
				`data` = `Data`,
				`published` = false; 
	END IF; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_agent_id` (`AgentName` VARCHAR(32)) RETURNS INT(11) BEGIN
	DECLARE `AgentId` INT DEFAULT '-1'; 
	DECLARE `NumberOfAgents` INT DEFAULT '0'; 

	DECLARE `DeviceNotFound` BOOLEAN DEFAULT FALSE; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `DeviceNotFound` = TRUE; 

	SET `NumberOfAgents` = (SELECT COUNT(*) 
						FROM `agent`
						WHERE (`name` = `AgentName`)
						ORDER BY `id` DESC
						LIMIT 1); 
	IF (`NumberOfAgents` > '0') THEN
		SET `AgentId` = (SELECT `id` AS `agent_id` 
							FROM `agent`
							WHERE (`name` = `AgentName`)
							ORDER BY `id` DESC
							LIMIT 1); 
	ELSE
		SET `AgentId` = '-1'; 
	END IF; 

	RETURN `AgentId`; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_calc_list` (`ListCalcName` VARCHAR(32)) RETURNS TEXT CHARSET latin1 BEGIN
	DECLARE `Result` TEXT; 

	DECLARE `CalcId` INT; 
	DECLARE `CalcName` VARCHAR(32); 
	DECLARE `CalcType` VARCHAR(16); 
	DECLARE `CalcActive` BOOL; 

	DECLARE `DstAgentName` VARCHAR(32); 
	DECLARE `DstNodeName` VARCHAR(32); 
	DECLARE `DstDeviceName` VARCHAR(32); 
	DECLARE `DstVariableName` VARCHAR(32); 

	DECLARE `FirstItem` BOOL DEFAULT TRUE; 

	DECLARE `Done` INT DEFAULT FALSE; 
    DECLARE `Cursor` CURSOR FOR
		SELECT 	`calc`.`id`,
				`calc`.`name`,
				`calc`.`type`,
				`calc`.`active`,
				`agent`.`name`,
				`node`.`name`,
				`device`.`name`,
				`variable`.`name`
			FROM `calc`,`agent`,`node`,`device`,`variable`
			WHERE ((`calc`.`name`= `ListCalcName`) OR (`ListCalcName` = '---')) AND
				  (`variable`.`id` = `calc`.`variable_id`) AND
				  (`device`.`id` = `variable`.`device_id`) AND
				  (`node`.`id` = `device`.`node_id`) AND
				  (`agent`.`id` = `node`.`agent_id`)
		ORDER BY `calc`.`name` ASC; 

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

	OPEN `Cursor`; 

	SET `Result` = '['; 
	
	read_loop_get_calc: LOOP
		FETCH `Cursor`
			INTO `CalcId`,`CalcName`,`CalcType`,`CalcActive`,`DstAgentName`,`DstNodeName`,`DstDeviceName`,`DstVariableName`; 
    
		IF (`Done`) THEN
			SET `Result` = CONCAT(`Result`,']'); 
			
			LEAVE read_loop_get_calc; 
		END IF; 

		IF (`FirstItem` = FALSE) THEN
			SET `Result` = CONCAT(`Result`,','); 
		END IF; 

		SET `FirstItem` = FALSE; 

		SET `Result` = CONCAT(`Result`,'{name:"',`CalcName`,'",type:"',`CalcType`,'",active:"',`CalcActive`,'",',
									   'dst: {agent:"',`DstAgentName`,'",node:"',`DstNodeName`,'",device:"',`DstDeviceName`,'",variable:"',`DstVariableName`,'"}'); 

		IF (`ListCalcName` = '---') THEN
			SET `Result` = CONCAT(`Result`,'}'); 
		ELSE
			get_list_of_input_variables: BEGIN
				DECLARE `AgentName` VARCHAR(32); 
				DECLARE `NodeName` VARCHAR(32); 
				DECLARE `DeviceName` VARCHAR(32); 
				DECLARE `VariableName` VARCHAR(32); 

				DECLARE `FirstItem` BOOL DEFAULT TRUE; 

				DECLARE `Done` INT DEFAULT FALSE; 
				DECLARE `Cursor` CURSOR FOR
				SELECT 	`agent`.`name`,
						`node`.`name`,
						`device`.`name`,
						`variable`.`name`
					FROM `calc_input`,`agent`,`node`,`device`,`variable`
					WHERE
						(`calc_input`.`calc_id` = `CalcId`) AND
						(`variable`.`id` = `calc_input`.`variable_id`) AND
						(`device`.`id` = `variable`.`device_id`) AND
						(`node`.`id` = `device`.`node_id`) AND
						(`agent`.`id` = `node`.`agent_id`)
					ORDER BY `agent`.`name` ASC, `node`.`name` ASC, `device`.`name` ASC, `variable`.`name` ASC; 

				DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

				OPEN `Cursor`; 

				SET `Result` = CONCAT(`Result`,', inputs:['); 

				read_loop_get_calc_input: LOOP
					FETCH `Cursor`
						INTO `AgentName`,`NodeName`,`DeviceName`,`VariableName`; 
		
					IF (`Done`) THEN
						SET `Result` = CONCAT(`Result`,']'); 
						LEAVE read_loop_get_calc_input; 
					END IF; 

					IF (`FirstItem` = FALSE) THEN
						SET `Result` = CONCAT(`Result`,','); 
					END IF; 

					SET `FirstItem` = FALSE; 
					SET `Result` = CONCAT(`Result`,'{agent:"',`AgentName`,'",node:"',`NodeName`,'",device:"',`DeviceName`,'",variable:"',`VariableName`,'"}'); 
		
				END LOOP read_loop_get_calc_input; 

			END get_list_of_input_variables; 

			SET `Result` = CONCAT(`Result`,'}'); 
		END IF; 

	END LOOP read_loop_get_calc; 

	SET `Result` = CONCAT(`Result`,']'); 

	RETURN `Result`; 
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_data_json` (`VariableId` INT, `DeltaTime` INT) RETURNS TEXT CHARSET latin1 BEGIN
    DECLARE `DataType` ENUM ('bool','int','float','text'); 
    DECLARE `DataValue` TEXT; 
    DECLARE `DataTime` INT; 
    DECLARE `Result` TEXT; 
 
	DECLARE `DeviceNotFound` BOOLEAN DEFAULT FALSE; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `DeviceNotFound` = TRUE; 

    SET `DataValue` = ''; 
    IF (`VariableId` != NULL) THEN
		SET `DataType` = (SELECT `data_type`
							FROM `variable`
                            WHERE (`id` = `VariableId`)); 
                            
		CASE `DataType`
			WHEN 'bool' THEN
				SELECT `data`,`time` 
					INTO `DataValue`,`DataTime`
                    FROM `data_bool`
					WHERE 
						(`variable_id` = `VariableId`) AND 
                        (`time` <= (UNIX_TIMESTAMP() - `DeltaTime`))
					ORDER BY `time` DESC
					LIMIT 1; 
            WHEN 'int' THEN
				SELECT `data`,`time` 
					INTO `DataValue`,`DataTime`
                    FROM `data_int`
					WHERE 
						(`variable_id` = `VariableId`) AND 
                        (`time` <= (UNIX_TIMESTAMP() - `DeltaTime`))
					ORDER BY `time` DESC
					LIMIT 1; 
            WHEN 'float' THEN
				SELECT `data`,`time` 
					INTO `DataValue`,`DataTime`
                    FROM `data_float`
					WHERE 
						(`variable_id` = `VariableId`) AND 
                        (`time` <= (UNIX_TIMESTAMP() - `DeltaTime`))
					ORDER BY `time` DESC
					LIMIT 1; 
            ELSE
				SELECT `data`,`time` 
					INTO `DataValue`,`DataTime`
                    FROM `data_text`
					WHERE 
						(`variable_id` = `VariableId`) AND 
                        (`time` <= (UNIX_TIMESTAMP() - `DeltaTime`))
					ORDER BY `time` DESC
					LIMIT 1; 
		END CASE; 
  
		IF ((`DeviceNotFound`) OR (`DataValue` = '')) THEN
			SET `Result` = '{}'; 
		ELSE
			SET `Result` = CONCAT('{time:"',`DataTime`,'",'
				   'data:"',`DataValue`,'"}  '); 
		END IF; 
    END IF; 
    
	RETURN `Result`; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_device_id` (`AgentName` VARCHAR(32), `NodeName` VARCHAR(32), `DeviceName` VARCHAR(32)) RETURNS INT(11) BEGIN
	DECLARE `DeviceId` INT DEFAULT '-1'; 
	DECLARE `NumberOfDevices` INT; 

	SET `NumberOfDevices` = (SELECT COUNT(`device`.`id`)
						FROM `device`,`node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`device`.`name` = `DeviceName`) AND
								(`agent`.`id` = `node`.`agent_id`) AND 
								(`node`.`id` = `device`.`node_id`))); 

	IF (`NumberOfDevices` > '0') THEN
		SET `DeviceId` = (SELECT `device`.`id` 
						FROM `device`,`node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`device`.`name` = `DeviceName`) AND
								(`agent`.`id` = `node`.`agent_id`) AND 
								(`node`.`id` = `device`.`node_id`))
						ORDER BY `device`.`id` DESC
						LIMIT 1); 
	ELSE
		SET `DeviceId`= '-1'; 
	END IF; 

	RETURN `DeviceId`; 
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_latest_variable_data` (`VariableId` INT) RETURNS TEXT CHARSET latin1 BEGIN
    DECLARE `DataType` ENUM ('bool','int','float','text'); 
    DECLARE `LatestData` TEXT; 
 
	DECLARE `DeviceNotFound` BOOLEAN DEFAULT FALSE; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `DeviceNotFound` = TRUE; 

    SET `LatestData` = ''; 
    IF (`VariableId` != NULL) THEN
		SET `DataType` = (SELECT `data_type`
							FROM `variable`
                            WHERE (`id` = `VariableId`)); 
                            
		CASE `DataType`
			WHEN 'bool' THEN
				SET `LatestData` = (SELECT `data` 
										FROM `data_bool`
                                        WHERE (`variable_id` = `VariableId`)
                                        ORDER BY `time` DESC
                                        LIMIT 1); 
            WHEN 'int' THEN
				SET `LatestData` = (SELECT `data` 
										FROM `data_int`
                                        WHERE (`variable_id` = `VariableId`)
                                        ORDER BY `time` DESC
                                        LIMIT 1); 
            WHEN 'float' THEN
				SET `LatestData` = (SELECT `data` 
										FROM `data_float`
                                        WHERE (`variable_id` = `VariableId`)
                                        ORDER BY `time` DESC
                                        LIMIT 1); 
            ELSE
				SET `LatestData` = (SELECT `data` 
										FROM `data_text`
                                        WHERE (`variable_id` = `VariableId`)
                                        ORDER BY `time` DESC
                                        LIMIT 1); 
		END CASE; 
  
		IF (`DeviceNotFound`) THEN
			SET `LatestData` = NULL; 
		END IF; 
    END IF; 
    
	RETURN `LatestData`; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_list_of_agents` () RETURNS TEXT CHARSET latin1 BEGIN
	DECLARE `result`TEXT; 

	DECLARE `Name` VARCHAR(32); 
	DECLARE `Revision` VARCHAR(16); 
	DECLARE `LastAccess` INT; 
	DECLARE `State` VARCHAR(16); 

	DECLARE `FirstUnit` INT DEFAULT TRUE; 

	DECLARE `done` INT DEFAULT FALSE; 
	DECLARE `cur` CURSOR FOR
		SELECT 	`agent`.`name`,
				`agent`.`ver`,
				`agent`.`agent_state`,
				`agent`.`agent_last_access`
			FROM `agent`
			ORDER BY `name` ASC; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = TRUE; 

	OPEN `cur`; 

	SET `result` = CONCAT('{name: "list-of-agents",',
						   'rev: "1.0",',
						   'agents: ['); 

	read_loop: LOOP
		FETCH `cur`INTO `Name`,`Revision`,`State`,`LastAccess`; 

		IF (`done`) THEN
			LEAVE read_loop; 
		END IF; 

		IF (`FirstUnit` != TRUE) THEN
			SET `result` = CONCAT(`result`,','); 
		ELSE
			SET `FirstUnit` = FALSE; 
		END IF; 
			
		SET `result` = CONCAT(`result`,
								'{last_access: "', FROM_UNIXTIME(`LastAccess`), '",',
								 'name: "', `Name`, '",',
								 'rev: "', `Revision`, '",',
								 'state: "', `State`, '"}'); 
	END LOOP; 

	SET `result` = CONCAT(`result`,']}'); 
	
RETURN `result`; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_list_of_devices` (`AgentName` VARCHAR(32), `NodeName` VARCHAR(32)) RETURNS TEXT CHARSET latin1 BEGIN
	DECLARE `result`TEXT; 

	DECLARE `Name` VARCHAR(32); 
	DECLARE `Revision` VARCHAR(16); 
	DECLARE `Type` VARCHAR(16); 

	DECLARE `FirstUnit` INT DEFAULT TRUE; 

	DECLARE `done` INT DEFAULT FALSE; 
	DECLARE `cur` CURSOR FOR
		SELECT 	`device`.`name`
			FROM `device`,`node`,`agent`
			WHERE	(`agent`.`name` = `AgentName`) AND
					(`node`.`name` = `NodeName`) AND
					(`agent`.`id` = `node`.`agent_id`) AND
					(`node`.`id` = `device`.`node_id`)
			ORDER BY `node`.`id` ASC; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = TRUE; 

	OPEN `cur`; 

	SET `result` = CONCAT('{name: "list-of-devices",',
						   'agent: "',`AgentName`,'",',
						   'node: "',`NodeName`,'",',
						   'rev: "1.0",',
						   'devices: ['); 

	read_loop: LOOP
		FETCH `cur`INTO `Name`; 

		IF (`done`) THEN
			LEAVE read_loop; 
		END IF; 

		IF (`FirstUnit` != TRUE) THEN
			SET `result` = CONCAT(`result`,','); 
		ELSE
			SET `FirstUnit` = FALSE; 
		END IF; 
			
		SET `result` = CONCAT(`result`,
								'{name: "', `Name`, '"}'); 
	END LOOP; 

	SET `result` = CONCAT(`result`,']'); 
	
RETURN `result`; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_list_of_nodes` (`AgentName` VARCHAR(32)) RETURNS TEXT CHARSET latin1 BEGIN
	DECLARE `result`TEXT; 

	DECLARE `Name` VARCHAR(32); 
	DECLARE `Revision` VARCHAR(16); 
	DECLARE `Type` VARCHAR(16); 

	DECLARE `FirstUnit` INT DEFAULT TRUE; 

	DECLARE `done` INT DEFAULT FALSE; 
	DECLARE `cur` CURSOR FOR
		SELECT 	`node`.`name`,
				`node`.`ver`,
				`node`.`type`
			FROM `node`,`agent`
			WHERE	(`agent`.`name` = `AgentName`) AND
					(`agent`.`id` = `node`.`agent_id`)
			ORDER BY `node`.`id` ASC; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = TRUE; 

	OPEN `cur`; 

	SET `result` = CONCAT('{name: "list-of-nodes",',
						   'agent: "',`AgentName`,'",',
						   'rev: "1.0",',
						   'nodes: ['); 

	read_loop: LOOP
		FETCH `cur`INTO `Name`,`Revision`,`Type`; 

		IF (`done`) THEN
			LEAVE read_loop; 
		END IF; 

		IF (`FirstUnit` != TRUE) THEN
			SET `result` = CONCAT(`result`,','); 
		ELSE
			SET `FirstUnit` = FALSE; 
		END IF; 

		SET `result` = CONCAT(`result`,
								'{name: "', `Name`, '",',
								 'rev: "', `Revision`, '",',
								 'type: "', `Type`, '"}'); 
	END LOOP; 

	SET `result` = CONCAT(`result`,']}'); 
	
RETURN `result`; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_list_of_variables` (`AgentName` VARCHAR(32), `NodeName` VARCHAR(32), `DeviceName` VARCHAR(32)) RETURNS TEXT CHARSET latin1 BEGIN
	DECLARE `result`TEXT; 

	DECLARE `Name` VARCHAR(32); 
	DECLARE `Primary` INT; 
	DECLARE `Output` INT; 
	DECLARE `DataType` VARCHAR(16); 
	DECLARE `DeviceType` VARCHAR(16); 
	DECLARE `WrapAround` INT; 
	DECLARE `WrapAroundOffset` INT; 
	DECLARE `DataCoef` FLOAT; 
	DECLARE `DataOffset` FLOAT; 

	DECLARE `FirstUnit` INT DEFAULT TRUE; 

	DECLARE `done` INT DEFAULT FALSE; 
	DECLARE `cur` CURSOR FOR
		SELECT 	`variable`.`name`,
				`variable`.`primary`,
				`variable`.`output`,
				`variable`.`data_type`,
				`variable`.`device_type`,
				`variable`.`wraparound`,
				`variable`.`wraparound_offset`,
				`variable`.`data_coef`,
				`variable`.`data_offset`
			FROM `variable`,`device`,`node`,`agent`
			WHERE	(`agent`.`name` = `AgentName`) AND
					(`node`.`name` = `NodeName`) AND
					(`device`.`name` = `DeviceName`) AND
					(`agent`.`id` = `node`.`agent_id`) AND
					(`node`.`id` = `device`.`node_id`) AND
					(`device`.`id` = `variable`.`device_id`)
			ORDER BY `variable`.`id` ASC; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = TRUE; 

	OPEN `cur`; 

	SET `result` = CONCAT('{name: "list-of-variables",',
						   'agent: "',`AgentName`,'",',
						   'node: "',`NodeName`,'",',
						   'device: "',`DeviceName`,'",',
						   'rev: "1.0",',
						   '{variables: ['); 

	read_loop: LOOP
		FETCH `cur`INTO `Name`,`Primary`,`Output`,`DataType`,`DeviceType`,`WrapAround`,`WrapAroundOffset`,`DataCoef`,`DataOffset`; 

		IF (`done`) THEN
			LEAVE read_loop; 
		END IF; 

		IF (`FirstUnit` != TRUE) THEN
			SET `result` = CONCAT(`result`,','); 
		ELSE
			SET `FirstUnit` = FALSE; 
		END IF; 
			
		SET `result` = CONCAT(`result`,
								'{name: "', `Name`, '",',
								'primary: "',`Primary`,'",',
								'output: "',`Output`,'",',
								'data_type: "',`DataType`,'",',
								'dev_type: "',`DeviceType`,'",',
								'wraparound: "',`WrapAround`,'",',
								'wraparound_offset: "',`WrapAroundOffset`,'",',
								'data_coef: "',`DataCoef`,'",',
								'data_offset: "',`DataOffset`,'"',
								'}'); 
	END LOOP; 

	SET `result` = CONCAT(`result`,']}'); 
	
RETURN `result`; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_node_id` (`AgentName` VARCHAR(32), `NodeName` VARCHAR(32)) RETURNS INT(11) BEGIN
	DECLARE `NodeId` INT DEFAULT '-1'; 
	DECLARE `NumberOfNodes` INT DEFAULT '0'; 

	SET `NumberOfNodes` = (SELECT COUNT(`node`.`id`) 
						FROM `node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`agent`.`id` = `node`.`agent_id`))); 

	IF (`NumberOfNodes` > '0') THEN
		SET `NodeId` = (SELECT `node`.`id` 
						FROM `node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`agent`.`id` = `node`.`agent_id`))
						ORDER BY `node`.`id` DESC
						LIMIT 1); 
	ELSE
		SET `NodeId`= '-1'; 
	END IF; 

	RETURN `NodeId`; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_variable_id` (`AgentName` VARCHAR(32), `NodeName` VARCHAR(32), `DeviceName` VARCHAR(32), `VariableName` VARCHAR(32)) RETURNS INT(11) BEGIN
	DECLARE `VariableId` INT DEFAULT '-1'; 
	DECLARE `NumberOfVariables` INT; 

	SET `NumberOfVariables` = (SELECT COUNT(`variable`.`id`) 
						FROM `variable`,`device`,`node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`device`.`name` = `DeviceName`) AND
								(`variable`.`name` = `variableName`) AND
								(`agent`.`id` = `node`.`agent_id`) AND 
								(`node`.`id` = `device`.`node_id`) AND 
								(`device`.`id` = `variable`.`device_id`))); 

	IF (`NumberOfVariables` > '0') THEN
		SET `VariableId` = (SELECT `variable`.`id` 
						FROM `variable`,`device`,`node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`device`.`name` = `DeviceName`) AND
								(`variable`.`name` = `variableName`) AND
								(`agent`.`id` = `node`.`agent_id`) AND 
								(`node`.`id` = `device`.`node_id`) AND 
								(`device`.`id` = `variable`.`device_id`))
						ORDER BY `variable`.`id` DESC
						LIMIT 1); 
	ELSE
		SET `VariableId`= '-1'; 
	END IF; 

	RETURN `VariableId`; 
END$$

DELIMITER ;

CREATE TABLE `agent` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `ver` varchar(16) DEFAULT '---',
  `msg_version` varchar(8) NOT NULL DEFAULT '1.0',
  `agent_state` enum('unknown','connected','timeout','non-validated') NOT NULL DEFAULT 'unknown',
  `agent_last_access` int(11) NOT NULL DEFAULT '0' COMMENT 'Updated with current epoch time at every received message',
  `info` text COMMENT 'Used for adding information about for example physical and logical location of the agent'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `calc` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `type` varchar(16) NOT NULL,
  `variable_id` int(11) NOT NULL,
  `active` tinyint(4) NOT NULL DEFAULT '0',
  `data_trans_key` varchar(32) NOT NULL DEFAULT 'undefined-key' COMMENT 'A key value used to identify the transaction where the initial data was stored '
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `calc_input` (
  `id` int(11) NOT NULL,
  `calc_id` int(11) NOT NULL,
  `variable_id` int(11) NOT NULL,
  `modified` int(1) DEFAULT '0',
  `modified_time` int(11) DEFAULT '0',
  `data_trans_key` varchar(32) DEFAULT 'Undefined transition key'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `calc_param` (
  `id` int(11) NOT NULL,
  `calc_id` int(11) NOT NULL,
  `name` varchar(16) NOT NULL,
  `value` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `data_bool` (
  `id` int(11) UNSIGNED NOT NULL,
  `variable_id` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `data` binary(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `data_float` (
  `id` int(11) UNSIGNED NOT NULL,
  `variable_id` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `data` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `data_int` (
  `id` int(11) UNSIGNED NOT NULL,
  `variable_id` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `data` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `data_publish` (
  `id` int(11) NOT NULL,
  `variable_id` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `published` int(1) NOT NULL DEFAULT '0',
  `data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `data_text` (
  `id` int(11) UNSIGNED NOT NULL,
  `variable_id` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `data` text NOT NULL,
  `error_code` int(11) NOT NULL DEFAULT '0',
  `error_severity` enum('na','observation','warning','error') NOT NULL DEFAULT 'na'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `device` (
  `id` int(11) NOT NULL,
  `name` varchar(32) DEFAULT NULL,
  `node_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE `latest_data_bool` (
`Time` datetime
,`Data` binary(1)
,`Source` varchar(131)
);
CREATE TABLE `latest_data_float` (
`Time` datetime
,`Data` float
,`Source` varchar(131)
,`Variable id` int(11)
,`Epoch time` int(11)
);
CREATE TABLE `latest_data_int` (
`Time` datetime
,`Data` int(11)
,`Source` varchar(131)
,`Variable id` int(11)
,`Epoch time` int(11)
);
CREATE TABLE `latest_data_out_float` (
`Time` datetime
,`Data` float
,`Source` varchar(131)
,`Variable id` int(11)
,`Epoch time` int(11)
);
CREATE TABLE `latest_data_text` (
`Time` datetime
,`Data` text
,`Source` varchar(131)
);
CREATE TABLE `list_all_calc` (
`CalcName` varchar(32)
,`VarId` int(11)
);
CREATE TABLE `list_all_info` (
`NameString` varchar(131)
,`VariableId` int(11)
);
CREATE TABLE `list_all_unpublished_data` (
`DataPublishId` int(11)
,`VariableId` int(11)
,`DataTime` int(11)
,`DataValue` text
,`TopicAddress` varchar(131)
,`Payload` mediumtext
);

CREATE TABLE `node` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL DEFAULT 'Not defined',
  `ver` varchar(16) NOT NULL DEFAULT '---',
  `type` varchar(16) NOT NULL DEFAULT '---',
  `agent_id` int(11) DEFAULT NULL,
  `timeout` int(11) NOT NULL DEFAULT '600',
  `info` text COMMENT 'Used for adding a description if the physical location of the node'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `variable` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `primary` tinyint(4) NOT NULL DEFAULT '1',
  `output` tinyint(4) NOT NULL DEFAULT '0',
  `device_id` int(11) DEFAULT NULL,
  `data_type` enum('bool','int','float','text') NOT NULL DEFAULT 'text',
  `device_type` enum('dynamic','semistatic','static') NOT NULL DEFAULT 'dynamic',
  `wraparound` int(11) DEFAULT NULL COMMENT 'Wraparound value valid for accumulated type of devices.',
  `wraparound_offset` int(11) NOT NULL DEFAULT '0' COMMENT 'Every time a wraparound occur, this value will be updated with the old figure plus the wraparound value and the data stored in the unitdata_float table will be the received value + this value.',
  `output_file_path` varchar(120) DEFAULT NULL,
  `data_coef` float NOT NULL DEFAULT '1',
  `data_offset` float NOT NULL DEFAULT '0',
  `retain` int(11) DEFAULT '0' COMMENT 'One '
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
DROP TABLE IF EXISTS `latest_data_bool`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_bool`  AS  select from_unixtime(`data_bool`.`time`) AS `Time`,`data_bool`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_bool`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source` from `data_bool` order by `data_bool`.`time` desc ;
DROP TABLE IF EXISTS `latest_data_float`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_float`  AS  select from_unixtime(`data_float`.`time`) AS `Time`,`data_float`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_float`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source`,`data_float`.`variable_id` AS `Variable id`,`data_float`.`time` AS `Epoch time` from `data_float` order by `data_float`.`time` desc limit 100 ;
DROP TABLE IF EXISTS `latest_data_int`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_int`  AS  select from_unixtime(`data_int`.`time`) AS `Time`,`data_int`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_int`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source`,`data_int`.`variable_id` AS `Variable id`,`data_int`.`time` AS `Epoch time` from `data_int` order by `data_int`.`time` desc limit 100 ;
DROP TABLE IF EXISTS `latest_data_out_float`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_out_float`  AS  select from_unixtime(`data_float`.`time`) AS `Time`,`data_float`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_float`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source`,`data_float`.`variable_id` AS `Variable id`,`data_float`.`time` AS `Epoch time` from (`data_float` join `variable`) where ((`data_float`.`variable_id` = `variable`.`id`) and (`variable`.`output` = '1')) order by `data_float`.`time` desc limit 100 ;
DROP TABLE IF EXISTS `latest_data_text`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_text`  AS  select from_unixtime(`data_text`.`time`) AS `Time`,`data_text`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_text`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source` from `data_text` order by from_unixtime(`data_text`.`time`) desc limit 100 ;
DROP TABLE IF EXISTS `list_all_calc`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `list_all_calc`  AS  select `calc`.`name` AS `CalcName`,`calc_input`.`variable_id` AS `VarId` from (`calc` join `calc_input`) where (`calc`.`id` = `calc_input`.`calc_id`) ;
DROP TABLE IF EXISTS `list_all_info`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `list_all_info`  AS  select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) AS `NameString`,`variable`.`id` AS `VariableId` from (((`agent` join `node`) join `device`) join `variable`) where ((`agent`.`id` = `node`.`agent_id`) and (`node`.`id` = `device`.`node_id`) and (`device`.`id` = `variable`.`device_id`)) order by `agent`.`id` desc,`node`.`id`,`device`.`id`,`variable`.`id` ;
DROP TABLE IF EXISTS `list_all_unpublished_data`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `list_all_unpublished_data`  AS  select `data_publish`.`id` AS `DataPublishId`,`data_publish`.`variable_id` AS `VariableId`,`data_publish`.`time` AS `DataTime`,`data_publish`.`data` AS `DataValue`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_publish`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `TopicAddress`,concat('{"time":"',`data_publish`.`time`,'","data":"',`data_publish`.`data`,'"}') AS `Payload` from `data_publish` where (`data_publish`.`published` = 0) order by `data_publish`.`time`,`data_publish`.`id` ;


ALTER TABLE `agent`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `calc`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `Update` (`active`,`id`) USING BTREE,
  ADD UNIQUE KEY `Namn` (`name`) USING BTREE;

ALTER TABLE `calc_input`
  ADD PRIMARY KEY (`id`),
  ADD KEY `VariableIndex` (`variable_id`,`calc_id`) USING BTREE;

ALTER TABLE `calc_param`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `CreateLogicalCalcParam` (`calc_id`,`name`);

ALTER TABLE `data_bool`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `index2` (`variable_id`,`time`);

ALTER TABLE `data_float`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `index2` (`variable_id`,`time`);

ALTER TABLE `data_int`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `index2` (`variable_id`,`time`);

ALTER TABLE `data_publish`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `StoreIndex` (`variable_id`,`time`) USING BTREE;

ALTER TABLE `data_text`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `device`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `node`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `variable`
  ADD PRIMARY KEY (`id`);


ALTER TABLE `agent`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;
ALTER TABLE `calc`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;
ALTER TABLE `calc_input`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;
ALTER TABLE `calc_param`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;
ALTER TABLE `data_bool`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3611;
ALTER TABLE `data_float`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4961392;
ALTER TABLE `data_int`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=817263;
ALTER TABLE `data_publish`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=725577;
ALTER TABLE `data_text`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3920183;
ALTER TABLE `device`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=324;
ALTER TABLE `node`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=181;
ALTER TABLE `variable`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=337;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
