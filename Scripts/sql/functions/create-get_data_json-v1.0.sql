-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2016-12-01
-- Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-get_data_json-xxx.js
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- function get_data_json
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_data_json`(
`VariableId` INT,
`DeltaTime` INT) RETURNS text CHARSET latin1
BEGIN
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
			SET `Result` = CONCAT('{"time":"',`DataTime`,'",'
				               '"data":"',`DataValue`,'"}  '); 
		END IF; 
    END IF; 
    
	RETURN `Result`; 
END$$

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

