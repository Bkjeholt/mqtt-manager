-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-03-16
-- Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-store_data-vx.x.sql
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- procedure store_data_vid
-- -----------------------------------------------------

DELIMITER $$

CREATE PROCEDURE `store_data_vid`(
IN `VariableId` INT,
IN `Time` INT,
IN `Data` TEXT)
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

	SELECT  `data_type` AS `DataType`,
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
                            check_and_update_for_wraparound: BEGIN
                                DECLARE `DataNotFound` BOOLEAN DEFAULT FALSE; 
                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET `DataNotFound` = TRUE; 

                                SET `CurrentData` = `Data` + `WrapAroundOffset`; 
                                SET `LatestData` = (SELECT `data` 
                                                        FROM `data_int` 
                                                        WHERE (`variable_id` = `VariableId`)
                                                        ORDER BY `time` DESC
                                                        LIMIT 1); 
                                IF (`DataNotFound` = FALSE) THEN
                                    IF (`CurrentData` < `LatestData`) THEN
						SET `CurrentData` = `CurrentData` + `WrapAround`; 
                        
						UPDATE `variable`
							SET `wraparound_offset` = `wraparound_offset` + `wraparound`
							WHERE (`id` = `VariableId`); 
                                    END IF;
                                END IF;
                            END check_and_update_for_wraparound;
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
            INSERT INTO `data_modified` (`variable_id`,`time`)
                VALUE (`VariableId`,`Time`);

# 		UPDATE `calc_input`
# 			SET `modified` = TRUE,
#                             `modified_time` = `Time`,
#                             `data_trans_key` = `DataTransactionKey`
# 			WHERE (`variable_id` = `VariableId`) AND
# 				  ((`modified` = FALSE) OR
# 				   (`modified_time` < `Time`)); 
	END update_calc_mod_info; 

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
	SET `DataTransactionKey` = CONCAT('key-',`VariableId`,'-',FROM_UNIXTIME(`Time`)+'0'); 

	CALL `store_data_vid`(`VariableId`, `Time`, `Data`,`DataTransactionKey`); 

	UPDATE `agent`
            SET `agent_last_access` = unix_timestamp()
            WHERE (`id` = `get_agent_id`(`AgentName`)); 

-- 	CALL `calc_modified`(); 

        SELECT `DataTransactionKey`, `VariableId`,`Time`;

    END IF; 
    
END$$

-- -----------------------------------------------------
-- procedure store_data_calc
-- -----------------------------------------------------

CREATE PROCEDURE `store_data_calc`(
IN `DeviceId` INT,
IN `DstCalcVarNo` INT,
IN `SampleTime` INT,
IN `Data` TEXT)
BEGIN
    DECLARE `DstVariableId` INT;
    DECLARE `DstVariableIdNotFound` INT DEFAULT FALSE; 
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET `DstVariableIdNotFound` = TRUE; 

    SET `DstVariableId` = (SELECT `variable`.`id` 
                                FROM `variable` 
                                WHERE (`device_id` = `DeviceId`) AND
                                      (`calc_output_number` = `DstCalcVarNo`)
                                LIMIT 1); 

    IF (`DstVariableIdNotFound` = FALSE) THEN 
        CALL `store_data_vid`(`DstVariableId`, `SampleTime`,`Data`); 

    END IF;
END$$
DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

