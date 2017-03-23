-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-03-22
-- Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-calc_linear-vx.x.sql
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- procedure store_info_agent
-- -----------------------------------------------------

DELIMITER $$

CREATE PROCEDURE `calc_minmaxavg_overtime`(
    IN `DeviceId` INT,
    IN `SampleTime` INT)
BEGIN
-- 
-- 	Calculate to allocation value for what's defined in the calculations table. 
-- 	This is normally a conversion between a device and a sensor unit.

    DECLARE `InputVariableId` INT; 
    DECLARE `InputDataType` VARCHAR(16); 
    DECLARE `InputDataTime` INT; 
    DECLARE `InputDataAvaliable` BOOLEAN; 

    DECLARE `ResultMinValue` FLOAT;
    DECLARE `ResultMaxValue` FLOAT;
    DECLARE `ResultAvgValue` FLOAT;

    DECLARE `CalcCoef` FLOAT DEFAULT '1.0'; 
    DECLARE `CalcOffset` FLOAT DEFAULT '0'; 

    create_timing_info: BEGIN
        DECLARE `LastTime` INT;
        DECLARE `LastValue` FLOAT;

        DECLARE `LastDataAvailable` BOOLEAN DEFAULT FALSE;
        DECLARE `LoopCounter` INT DEFAULT '3';

        timing_loop: LOOP
            CALL `get_data_calc`(`DeviceId`,`LoopCounter`,`SampleTime`,`LastTime`,`LastValue`,`LastDataAvailable`);

            IF (`LastDataAvailable`) OR (`LoopCounter` = '1') THEN
                LEAVE timing_loop;
            END IF;

            SET `LoopCounter` = `LoopCounter` - '1';
        END LOOP;
    END create_timing_info;

    check_for_parameters: BEGIN
        DECLARE `ParamName` VARCHAR(16);
        DECLARE `ParamValue` VARCHAR(16);

        DECLARE `Done` BOOLEAN DEFAULT FALSE; 
        DECLARE `Cursor` CURSOR FOR
            SELECT `name`,`value`
                FROM `calc_param`
                WHERE (`device_id` = `DeviceId`);
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

        OPEN `Cursor`;

        parameter_scan_loop: LOOP
            FETCH `ParamName`,`ParamValue`;

            IF (`Done`) THEN
                LEAVE parameter_scan_loop;
            END IF;

            CASE (`ParamName`)
                WHEN 'time'     THEN SET `CalcTime` = `ParamValue`; 
                WHEN 'interval' THEN 
                    BEGIN
                        DECLARE `CurrentTime` DATETIME;
                        DECLARE `DataValue` TEXT; 
                        DECLARE `DataType` VARCHAR(16); 
                        DECLARE `DataTime` INT; 
                        DECLARE `DataExist`BOOLEAN DEFAULT FALSE; 
	
                        CALL `__get_data_test`((SELECT `variable_id` 
													FROM `calc` 
													WHERE (`id` = `CalcId`) 
                                                    LIMIT 1), 
										  '0',
										  `DataValue`,
										  `DataTime`,
										  `DataType`,
										  `DataExist` ); 

                        CASE (`CalcParamValue`)
                            WHEN '10min' THEN
                                BEGIN
                                    DECLARE `LastTime` INT;
                                    DECLARE `NewTime` INT;
                                    SET `LastTime` = (SELECT FROM_UNIXTIME(`DataTime`,'%i'));
                                    SET `NewTime` = (SELECT FROM_UNIXTIME(`Input_DataTime`,'%i'));
                                    IF ((`LastTime` = `NewTime`) AND (`DataExist`)) THEN
                                        SET `StoreCalculatedData` = FALSE;
                                    END IF;
                                    SET `CalcTime` = '600'; 
                                END;
                            WHEN 'hour' THEN
								BEGIN
									DECLARE `LastTime` INT;
									DECLARE `NewTime` INT;
                                    SET `LastTime` = (SELECT FROM_UNIXTIME(`DataTime`,'%h'));
                                    SET `NewTime` = (SELECT FROM_UNIXTIME(`Input_DataTime`,'%h'));
                                    IF ((`LastTime` = `NewTime`) AND (`DataExist`)) THEN
										SET `StoreCalculatedData` = FALSE;
                                    END IF;
									SET `CalcTime` = '3600'; 
								END;
                            ELSE
								BEGIN
                                -- Default use 24 hour average counting
									DECLARE `LastTime` INT;
									DECLARE `NewTime` INT;
                                    SET `LastTime` = (SELECT FROM_UNIXTIME(`DataTime`,'%d'));
                                    SET `NewTime` = (SELECT FROM_UNIXTIME(`Input_DataTime`,'%d'));
                                    IF ((`LastTime` = `NewTime`) AND (`DataExist`)) THEN
										SET `StoreCalculatedData` = FALSE;
                                    END IF;
                                
									SET `CalcTime` = '86400'; 
                                END;
                        END CASE;
					END;
			END CASE; 

        END LOOP parameter_scan_loop;
    END check_for_parameters;

-- 	Get input variable information

    SELECT `variable`.`id`,
           `variable`.`data_type`
        INTO `InputVariableId`,`InputDataType`
        FROM `variable`,`calc_input`
        WHERE (`calc_input`.`device_id`=`DeviceId`)
        LIMIT 1;

    CALL `get_data_vid_abs_time`((SELECT `variable_id` 
                                    FROM `calc_input` 
                                    WHERE (`device_id` = `DeviceId`) 
                                    LIMIT 1),
                                 `SampleTime`,
                                 `InputDataValue`,
                                 `InputDataTime`,
                                 `InputDataAvaliable`);

# INSERT INTO `data_text`(`variable_id`,`time`,`data`)
# 	VALUES
# 		('-1',UNIX_TIMESTAMP(),
# 		 CONCAT('Observation: _calc_linear (input data/time/type/existans)-> ',
# 				`InputDataValue`,'/',`InputDataTime`,'/',`InputDataType`,'/',
# `InputDataExist`)); 

    IF (`InputDataAvaliable`) THEN
        check_for_parameters: BEGIN
                DECLARE `ParamName` VARCHAR(16);
                DECLARE `ParamValue` VARCHAR(16);

                DECLARE `Done` BOOLEAN DEFAULT FALSE; 
                DECLARE `Cursor` CURSOR FOR
                    SELECT `name`,`value`
                        FROM `calc_param`
                        WHERE (`device_id` = `DeviceId`);
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

                OPEN `Cursor`;

                parameter_scan_loop: LOOP
                    FETCH `ParamName`,`ParamValue`;

                    IF (`Done`) THEN
                        LEAVE parameter_scan_loop;
                    END IF;

                    CASE (`ParamName`)
                        WHEN 'coef'   THEN SET `CalcCoef`   = `ParamValue`; 
                        WHEN 'offset' THEN SET `CalcOffset` = `ParamValue`;
                    END CASE;
                END LOOP parameter_scan_loop;

        END check_for_parameters;


    SELECT min(`data_float`.`data`),max(`data_float`.`data`),avg(`data_float`.`data`)
        INTO `ResultMinValue`,`ResultMaxValue`,`ResultAvgValue`
        FROM `data_float`,`calc_input`,`data_float`
        WHERE (`data_float`.`variable_id` = `calc_input`.`variable_id`) AND
              (`calc_input`.`device_id`=`DeviceId`) AND
              (`data_float`.`time` >= (`SampleTime`-`600`));




        CASE ((SELECT `variable`.`data_type` 
                                    FROM `calc_input`,`variable` 
                                    WHERE (`calc_input`.`device_id` = `DeviceId`) AND 
                                          (`variable`.`id` = `calc_input`.`variable_id`)
                                    LIMIT 1))
            WHEN 'float' THEN
                BEGIN
                    DECLARE `Data` FLOAT; 

                    SET `Data` = `InputDataValue`; 

# 					INSERT INTO `data_text`(`variable_id`,`time`,`data`)
# 						VALUES
# 							('-1',UNIX_TIMESTAMP(),
# 							 CONCAT('Observation: _calc_linear (Input data/time/type/existans/Coef/Offset)-> ',
# 							 `Data`,'/',`InputDataTime`,'/',`InputDataType`,'/',`InputDataExist`,'/',`CalcCoef`,'/',`CalcOffset`)); 

                    CALL `store_data_calc`(`DeviceId`, '1', `SampleTime`,(`Data`*`CalcCoef` + `CalcOffset`)); 

                END; 
            WHEN 'bool' THEN
                BEGIN
                    DECLARE `Data` BOOLEAN; 

                    SET `Data` = `InputDataValue`; 

                    CALL `store_data_calc`(`DeviceId`, '1', `SampleTime`,(`Data`*`CalcCoef` + `CalcOffset`)); 
                END; 
            WHEN 'int' THEN
                BEGIN
                    DECLARE `Data` BIGINT; 

                    SET `Data` = `InputDataValue`; 

                    CALL `store_data_calc`(`DeviceId`, '1', `SampleTime`,(`Data`*`CalcCoef` + `CalcOffset`)); 
                END; 
            WHEN 'text' THEN
                BEGIN
                    DECLARE `Data` TEXT;
                    
                    SET `Data` = `InputDataValue`; 
                    CALL `store_data_calc`(`DeviceId`, '1', `SampleTime`,`Data`);
                END;
            ELSE
                INSERT INTO `data_text`(`variable_id`,`time`,`data`)
					VALUES
						('-1',`DataTime`,
						 CONCAT('Error: Unsupported InputDataType (CalcId/CalcName/InputVariableId/InputVariableType)-> ',
						 `CalcId`,'/',`CalcName`,'/',(SELECT `variable_id` FROM `calc_input` WHERE (`calc_id` = `CalcId`) LIMIT 1),'/',`InputDataType`)); 

        END CASE; 
    END IF; 
END
DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

