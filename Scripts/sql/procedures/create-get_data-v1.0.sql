-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-03-23
-- Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-get_data-vx.x.sql
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- procedure get_data
-- -----------------------------------------------------

DELIMITER $$

CREATE PROCEDURE `get_data`(
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

CREATE PROCEDURE `get_data_vid_abs_time`(
IN `VariableId` INT,
IN `SampleTime` INT,
OUT `OutData` TEXT,
OUT `OutSampleTime` INT,
OUT `DataAvailable` BOOLEAN)
BEGIN
    DECLARE `DataType` ENUM ('bool','int','float','text'); 
    DECLARE `DataValue` TEXT; 
    DECLARE `DataTime` INT; 
    DECLARE `Result` TEXT; 
 
    DECLARE `DataNotFound` BOOLEAN DEFAULT FALSE; 
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET `DataNotFound` = TRUE; 

    SET `DataAvailable` = FALSE; 
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
                        (`time` <= `SampleTime`)
                    ORDER BY `time` DESC
                    LIMIT 1; 
            WHEN 'int' THEN
                SELECT `data`,`time` 
                    INTO `DataValue`,`DataTime`
                    FROM `data_int`
                    WHERE 
                        (`variable_id` = `VariableId`) AND 
                        (`time` <= `SampleTime`)
                    ORDER BY `time` DESC
                    LIMIT 1; 
            WHEN 'float' THEN
                    SELECT `data`,`time` 
                        INTO `DataValue`,`DataTime`
                        FROM `data_float`
                        WHERE 
                            (`variable_id` = `VariableId`) AND 
                            (`time` <= `SampleTime`)
                        ORDER BY `time` DESC
			LIMIT 1; 
            ELSE
                SELECT `data`,`time` 
                    INTO `DataValue`,`DataTime`
                    FROM `data_text`
                    WHERE 
                        (`variable_id` = `VariableId`) AND 
                        (`time` <= `SampleTime`)
                    ORDER BY `time` DESC
                    LIMIT 1; 
        END CASE; 
  
        SET `DataAvailable` = (`DataNotFound` != TRUE);

    END IF; 

END$$

CREATE PROCEDURE `get_data_calc`(
IN `DeviceId` INT,
IN `RequestedCalcVarNo` INT,
IN `RequestedTime` INT,
OUT `ResponseTime` INT,
OUT `ResponseData` TEXT,
OUT `ResponseDataAvailable` BOOLEAN )
BEGIN
    DECLARE `RequestedVariableId` INT;
    DECLARE `RequestedVariableIdNotFound` INT DEFAULT FALSE; 
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET `RequestedVariableIdNotFound` = TRUE; 

    SET `RequestedVariableId` = (SELECT `variable`.`id` 
                                FROM `variable` 
                                WHERE (`device_id` = `DeviceId`) AND
                                      (`calc_output_number` = `RequestedCalcVarNo`)
                                LIMIT 1); 

    IF (`RequestedVariableIdNotFound` = FALSE) THEN 
        BEGIN

        CALL `get_data_vid_abs_time`(`RequestedVariableId`, `RequestedTime`,
                                     `ResponseData`, `ResponseTime`, `ResponseDataAvailable` ); 

        END;
    ELSE
        BEGIN
            SET `ResponseDataAvailable` = FALSE;
        END;
    END IF;

END$$

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

