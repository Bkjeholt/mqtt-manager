-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-03-15
-- Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-get_data-vx.x.sql
-- Version    : 1.4
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

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

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

