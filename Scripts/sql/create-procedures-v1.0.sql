-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2016-12-01
-- Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-procedures.js
-- Version    : 1.1
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
-- procedure __get_data
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `__get_data`(
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
# 				INSERT INTO `data_bool`(`variable_id`,`time`,`data`)
# 					VALUES
# 						(`VariableId`, `Time`,`Data`); 
		WHEN 'int' THEN
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
#			INSERT INTO .`data_float`(`variable_id`,`time`,`data`)
# 				VALUES
# 					(`VariableId`,`Time`,(`Data`*`DataCoef`+`DataOffset`)); 
# 
			REPLACE INTO `data_float`
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
				`data` = `Data`,
				`published` = false; 
	END IF; 
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
-- procedure store_calc
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `store_calc`(
		IN `CalcName` VARCHAR(32),
		IN `CalcType` VARCHAR(16),
		IN `DstAgentName` VARCHAR(32),
		IN `DstNodeName` VARCHAR(32),
		IN `DstDeviceName` VARCHAR(32),
		IN `DstVariableName` VARCHAR(32))
BEGIN
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

		CALL `calc_modified`(); 

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
IN `WrapAround` INT ,
IN `DataCoef` FLOAT,
IN `DataOffset` FLOAT,
IN `OutputVar` TINYINT)
BEGIN
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

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

