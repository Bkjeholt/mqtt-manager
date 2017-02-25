-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-02-25
-- Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-procedures.js
-- Version    : 1.2
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- procedure __calc_avg
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_avg`(
			IN `CalcId` INT,
			IN `DataTransitionKey` VARCHAR(32))
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure __calc_avg1
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_avg1`(
			IN `CalcId` INT,
			IN `DataTransitionKey` VARCHAR(32))
BEGIN
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

# 		SET `NumberOfDatas` = (SELECT COUNT(`data_float`.`id`) 
# 								FROM `data_float` ,`calc_param`
# 								WHERE (`calc_input`.`calc_id` = `CalcId`) AND
# 									  (`data_float`.`variable_id` = `calc_input`.`variable_id`) AND
# 									  (`data_float`.`time` > `FromTime`) AND
# 									  (`data_float`.`time` <= `ToTime`) ); 

		INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						('-1', UNIX_TIMESTAMP(),CONCAT('Warning: __calc_avg (',`NumberOfDatas`,') Data ->',`NumberOfParams`)); 
	END IF; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure __calc_linear
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_linear`(
			IN `CalcId` INT,
			IN `DataTransitionKey` VARCHAR(32))
BEGIN
-- 
-- 	Calculate to allocation value for what's defined in the calculations table. 
-- 	This is normally a conversion between a device and a sensor unit.

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

-- 	Get input device data
	SELECT `variable_id`, `id` 
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
# 				`InputDataValue`,'/',`InputDataTime`,'/',`InputDataType`,'/',
`InputDataExist`)); 

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

# 					INSERT INTO `data_text`(`variable_id`,`time`,`data`)
# 						VALUES
# 							('-1',UNIX_TIMESTAMP(),
# 							 CONCAT('Observation: _calc_linear (Input data/time/type/existans/Coef/Offset)-> ',
# 							 `Data`,'/',`InputDataTime`,'/',`InputDataType`,'/',`InputDataExist`,'/',`CalcCoef`,'/',`CalcOffset`)); 

					SET `VariableId` = (SELECT `variable_id` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1); 
# 					SET `DataTransitionKey` = (SELECT `data_trans_key` FROM `calc` WHERE (`id` = `CalcId`) LIMIT 1); 

					CALL `__store_data`(`VariableId`, 
 									    `InputDataTime`,
 										(`Data`*`CalcCoef` + `CalcOffset`), 
 										`DataTransitionKey`); 

				END; 
			WHEN 'int' THEN
				BEGIN
					DECLARE `Data` BIGINT; 

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

DELIMITER ;

-- -----------------------------------------------------
-- procedure __calc_min
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_min`(
			IN `CalcId` INT,
			IN `DataTransitionKey` VARCHAR(32))
BEGIN
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

		CALL `__get_data`(`VariableId`, '0', 
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure __calc_power
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_power`(
			IN `CalcId` INT,
			IN `DataTransitionKey` VARCHAR(32))
BEGIN
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
	END get_parameter_information; 

-- 	Get input device data
	SELECT `variable_id`, `id` 
		INTO `VariableId`,`CalcInputId` 
		FROM `calc_input` 
		WHERE (`calc_id` = `CalcId`) 
		LIMIT 1; 

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

DELIMITER ;

-- -----------------------------------------------------
-- procedure __calc_scan_modified
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__calc_scan_modified`()
BEGIN
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

# 		UPDATE `calc` 
# 			SET `modified` = FALSE
# 			WHERE (`id` = `CalcId`); 

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

DELIMITER ;

-- -----------------------------------------------------
-- procedure calc_modified
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `calc_modified`()
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure get_data
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `get_data`(
IN `AgentName` VARCHAR(32),
IN `NodeName` VARCHAR(32),
IN `DeviceName` VARCHAR(32),
IN `VariableName` VARCHAR(32),
IN `DeltaTime` INT)
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure store_calc_activate
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_calc_activate`(
		IN `CalcName` VARCHAR(32),
		IN `CalcActive` BOOL )
BEGIN
	DECLARE `CalcId` INT; 

	SET `CalcId` = (SELECT `id` FROM `calc` WHERE (`name` = `CalcName`) LIMIT 1); 

    IF (`CalcId` >= '0') THEN
		UPDATE `calc`
			SET `active` = `CalcActive`
			WHERE (`id` = `CalcId`); 
	END IF; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure store_calc_input
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_calc_input`(
		IN `CalcName` VARCHAR(32),
		IN `SrcAgentName` VARCHAR(32),
		IN `SrcNodeName` VARCHAR(32),
		IN `SrcDeviceName` VARCHAR(32),
		IN `SrcVariableName` VARCHAR(32))
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure store_calc_param
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_calc_param`(
		IN `CalcName` VARCHAR(32),
		IN `ParamName` VARCHAR(16),
		IN `ParamValue` VARCHAR(32))
BEGIN
	DECLARE `CalcId` INT; 

	SET `CalcId` = (SELECT `id` FROM `calc` WHERE (`name` = `CalcName`) LIMIT 1); 

    IF (`CalcId` >= '0') THEN
		REPLACE INTO `calc_param`
			SET `calc_id`     = `CalcId`,
				`name`        = `ParamName`,
				`value`      = `ParamValue`; 
	END IF; 
END$$

DELIMITER ;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

