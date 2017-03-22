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

CREATE PROCEDURE `calc_linear`(
    IN `DeviceId` INT,
    IN `SampleTime` INT)
BEGIN
-- 
-- 	Calculate to allocation value for what's defined in the calculations table. 
-- 	This is normally a conversion between a device and a sensor unit.

    DECLARE `InputDataValue` TEXT; 
    DECLARE `InputDataType` VARCHAR(16); 
    DECLARE `InputDataTime` INT; 
    DECLARE `InputDataAvaliable` BOOLEAN; 

    DECLARE `ResultMinData` FLOAT;
    DECLARE `ResultMaxData` FLOAT;
    DECLARE `ResultSumData` FLOAT;
    DECLARE `ResultNumberOfVariables` INT DEFAULT '0';
    
--  Calculate min, max and avg figures for the included src variables

    DECLARE `Done` INT DEFAULT FALSE; 
    DECLARE `Cursor` CURSOR FOR
        SELECT  `variable_id` 
            FROM `calc_input`
            WHERE(`device_id` = `DeviceId`); 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

    OPEN `Cursor`; 

    read_input_data_loop: LOOP
        FETCH `Cursor`
            INTO `CalcInputId`,`VariableId`; 

        IF (`Done`) THEN
            LEAVE read_input_data_loop; 
        END IF; 

        CALL `get_data_vid_abs_time`(`VariableId`,
                                     `SampleTime`,
                                     `InputDataValue`,
                                     `InputDataTime`,
                                     `InputDataAvaliable`);
        SET `ResultNumberOfVariables` = `ResultNumberOfVariables` + '1';

        analyze_data: BEGIN
            IF (`FirstData`) THEN
                SET `FirstData` = FALSE;
                SET `ResultMinData` = `InputDataValue`;
                SET `ResultMaxData` = `InputDataValue`;
                SET `ResultSumData` = `InputDataValue`;
            ELSE
                IF (`ResultMinData` > `InputDataValue`) THEN
                    SET `ResultMinData` = `InputDataValue`;
                END IF;
                IF (`ResultMaxData` < `InputDataValue`) THEN
                    SET `ResultMaxData` = `InputDataValue`;
                END IF;
                SET `ResultSumData` = `ResultSumData` + `InputDataValue`;
            END IF;
        END analyze_data;

    END LOOP; 

    CALL `store_data_calc`(`DeviceId`, '1', `SampleTime`,`ResultMinData`); 
    CALL `store_data_calc`(`DeviceId`, '2', `SampleTime`,`ResultMaxData`); 
    CALL `store_data_calc`(`DeviceId`, '3', `SampleTime`,(`ResultSumData`/`ResultNumberOfVariables`); 

END
DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

