-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-03-15
-- Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-procedures-vx.x.sql
-- Version    : 1.4
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- procedure __get_data
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `xx__get_data`(
	IN `VariableId` INT,
	IN `DeltaTime` INT,
	OUT `DataValue` TEXT,
	OUT `DataTime` INT,
	OUT `DataType` VARCHAR(16),
	OUT `DataExist` BOOL)
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure __get_data_test
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__get_data_test`(
	IN `VariableId` INT,
	IN `DeltaTime` INT,
	OUT `DataValue` TEXT,
	OUT `DataTime` INT,
	OUT `DataType` VARCHAR(16),
	OUT `DataExist` BOOL)
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure __store_data
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__store_data`(
IN `VariableId` INT,
IN `Time` INT,
IN `Data` TEXT,
IN `DataTransactionKey` VARCHAR(32))
BEGIN
	DECLARE `DataType` ENUM('bool','int','float','text'); 
	DECLARE `DataCoef` FLOAT DEFAULT '1.0'; 
	DECLARE `DataOffset` FLOAT DEFAULT '0'; 
	DECLARE `DeviceType` ENUM ('dynamic','semistatic','static'); 
	DECLARE `WrapAround` BIGINT; 
	DECLARE `WrapAroundOffset` BIGINT; 
	DECLARE `PublishData` BOOL DEFAULT FALSE; 

        DECLARE `ResultData` TEXT;
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

                        SET `ResultData` = `Data`;

# 				INSERT INTO `data_bool`(`variable_id`,`time`,`data`)
# 					VALUES
# 						(`VariableId`, `Time`,`Data`); 
		WHEN 'int' THEN
			BEGIN
				DECLARE `LatestData` BIGINT; 
				DECLARE `CurrentData` BIGINT; 
                
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

                        SET `ResultData` = `CurrentData`;

			END; 
		WHEN 'float' THEN
#			INSERT INTO .`data_float`(`variable_id`,`time`,`data`)
# 				VALUES
# 					(`VariableId`,`Time`,(`Data`*`DataCoef`+`DataOffset`)); 
# 
			REPLACE INTO `data_float`
				SET	`variable_id` = `VariableId`,
					`time` = `Time`,
                                        `data` = (`Data`*`DataCoef`+`DataOffset`); 

                        SET `ResultData` = (`Data`*`DataCoef`+`DataOffset`);

		WHEN 'text' THEN
				INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						(`VariableId`, `Time`,`Data`); 

                                SET `ResultData` = `Data`;

		ELSE
				INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						(`VariableId`, `Time`,CONCAT('Warning: Non-supported datatype (',`DataType`,') Data ->',`Data`)); 

                                SET `ResultData` = `Data`;


	END CASE; 
    
	update_calc_mod_info: BEGIN
# 		UPDATE `calc`,`calc_input`
# 			SET `calc`.`modified` = TRUE,
# 				`calc`.`modified_time` = `Time`,
# 				`calc`.`data_trans_key` = `DataTransactionKey`
# 			WHERE (`calc`.`id` = `calc_input`.`calc_id`) AND
# 				  (`calc_input`.`variable_id` = `VariableId`) AND
# 				  ((`calc`.`modified` = FALSE) OR
# 				   (`calc`.`modified_time` < `Time`));		
		UPDATE `calc_input`
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
				`data` = `ResultData`,
				`published` = false; 
	END IF; 
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
-- procedure store_data
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_data`(
IN `AgentName` VARCHAR(32),
IN `NodeName` VARCHAR(32),
IN `DeviceName` VARCHAR(32),
IN `VariableName` VARCHAR(32),
IN `Time` INT,
IN `Data` TEXT)
BEGIN
	DECLARE `VariableId` INT DEFAULT '-1'; 
	DECLARE `DataTransactionKey` VARCHAR(32); 

	SET `VariableId` = `get_variable_id`(`AgentName`,`NodeName`,`DeviceName`,`VariableName`); 
    
    IF (`VariableId` >= '0') THEN
	SET `DataTransactionKey` = CONCAT('key-',`VariableId`,'-',`Time`); 

	CALL `__store_data`(`VariableId`, `Time`, `Data`,`DataTransactionKey`); 

	UPDATE `agent`
            SET `agent_last_access` = unix_timestamp()
            WHERE (`id` = `get_agent_id`(`AgentName`)); 

-- 	CALL `calc_modified`(); 

        SELECT `DataTransactionKey`, `VariableId`,`Time`;

    END IF; 
    
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure store_data_transaction_key
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_data_transaction_key`(
IN `AgentName` VARCHAR(32),
IN `NodeName` VARCHAR(32),
IN `DeviceName` VARCHAR(32),
IN `VariableName` VARCHAR(32),
IN `Time` INT,
IN `Data` TEXT,
IN `DataTransactionKey` VARCHAR(32))
BEGIN
	DECLARE `VariableId` INT DEFAULT '-1'; 

	SET `VariableId` = `get_variable_id`(`AgentName`,`NodeName`,`DeviceName`,`VariableName`); 
    
    IF (`VariableId` >= '0') THEN

		CALL `__store_data`(`VariableId`, `Time`, `Data`,`DataTransactionKey`); 

		UPDATE `agent`
			SET `agent_last_access` = unix_timestamp()
            WHERE (`id` = `get_agent_id`(`AgentName`)); 
    END IF; 
    
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure store_info_agent
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_info_agent`(
IN `AgentName` VARCHAR(32),
IN `AgentVer` VARCHAR(32))
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure store_info_device
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_info_device`(
IN `AgentName` VARCHAR(32),
IN `NodeName` VARCHAR(32),
IN `DeviceName` VARCHAR(32))
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure store_info_node
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_info_node`(
IN `AgentName` VARCHAR(32),
IN `NodeName` VARCHAR(32),
IN `NodeVer` VARCHAR(16),
IN `NodeType` VARCHAR(16))
BEGIN
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

DELIMITER ;

-- -----------------------------------------------------
-- procedure store_info_variable
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_info_variable`(
        IN `AgentName` VARCHAR(32),
        IN `NodeName` VARCHAR(32),
        IN `DeviceName` VARCHAR(32),
        IN `VariableName` VARCHAR(32),
        IN `DataType` VARCHAR(32),
        IN `DeviceType` VARCHAR(32),
        IN `WrapAround` BIGINT ,
        IN `DataCoef` FLOAT,
        IN `DataOffset` FLOAT,
        IN `OutputVar` TINYINT)
    BEGIN
	DECLARE `DeviceId` INT; 
	DECLARE `VariableId` INT; 
	DECLARE `Primary` TINYINT(1) DEFAULT TRUE; 
	DECLARE `CleanDAT` VARCHAR(32); 
	DECLARE `CleanDET` VARCHAR(32); 
	DECLARE `CleanWrapAround` BIGINT; 

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
				`data_type` = `CleanDAT`,
				`device_type` = `CleanDET`,
				`wraparound` = `CleanWrapAround`,
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
			 `CleanDAT`,`CleanDET`,`CleanWrapAround`,'0',`DataCoef`,`DataOffset`); 
		SET `VariableId` = LAST_INSERT_ID(); 
            ELSE
		CALL `store_info_device`(`AgentName`,`NodeName`,`DeviceName`); 

# 		INSERT INTO `data_text`(`variable_id`,`time`,`data`)
#                     VALUES
#                         ('-1',UNIX_TIMESTAMP(),
# 			 CONCAT('Warning: new variable -> Unexpected Device created  -> ',
# 						   `AgentName`,'/',`NodeName`,'/',`DeviceName`,'/',`VariableName`)); 

		INSERT INTO `variable`(`name`,`primary`,`output`,`device_id`,
                                       `data_type`,`device_type`,`wraparound`,`wraparound_offset`,`data_coef`,`data_offset`)
                    VALUES
                        (`VariableName`,FALSE,`OutputVar`,
                         `get_device_id`(`AgentName`,`NodeName`,`DeviceName`),
			 `CleanDAT`,`CleanDET`,`CleanWrapAround`,'0',`DataCoef`,`DataOffset`); 
                SET `VariableId` = LAST_INSERT_ID(); 

            END IF; 
	END IF; 
END$$

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

