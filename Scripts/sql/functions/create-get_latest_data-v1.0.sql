-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-03-16
-- Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-get_latest_data.js
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- function get_latest_data
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_latest_data`(
`VariableId` INT) RETURNS text CHARSET latin1
BEGIN
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

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

