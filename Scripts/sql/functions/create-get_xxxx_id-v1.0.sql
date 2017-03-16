-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-03-15
-- Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-get_xxxx_id-xxx.js
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- function get_agent_id
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_agent_id`(
`AgentName` VARCHAR(32)) RETURNS int(11)
BEGIN
	DECLARE `AgentId` INT DEFAULT '-1'; 
	DECLARE `NumberOfAgents` INT DEFAULT '0'; 

	DECLARE `DeviceNotFound` BOOLEAN DEFAULT FALSE; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `DeviceNotFound` = TRUE; 

	SET `NumberOfAgents` = (SELECT COUNT(*) 
						FROM `agent`
						WHERE (`name` = `AgentName`)
						ORDER BY `id` DESC
						LIMIT 1); 
	IF (`NumberOfAgents` > '0') THEN
		SET `AgentId` = (SELECT `id` AS `agent_id` 
							FROM `agent`
							WHERE (`name` = `AgentName`)
							ORDER BY `id` DESC
							LIMIT 1); 
	ELSE
		SET `AgentId` = '-1'; 
	END IF; 

	RETURN `AgentId`; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function get_device_id
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_device_id`(
`AgentName` VARCHAR(32),
`NodeName` VARCHAR(32),
`DeviceName` VARCHAR(32)) RETURNS int(11)
BEGIN
	DECLARE `DeviceId` INT DEFAULT '-1'; 
	DECLARE `NumberOfDevices` INT; 

	SET `NumberOfDevices` = (SELECT COUNT(`device`.`id`)
						FROM `device`,`node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`device`.`name` = `DeviceName`) AND
								(`agent`.`id` = `node`.`agent_id`) AND 
								(`node`.`id` = `device`.`node_id`))); 

	IF (`NumberOfDevices` > '0') THEN
		SET `DeviceId` = (SELECT `device`.`id` 
						FROM `device`,`node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`device`.`name` = `DeviceName`) AND
								(`agent`.`id` = `node`.`agent_id`) AND 
								(`node`.`id` = `device`.`node_id`))
						ORDER BY `device`.`id` DESC
						LIMIT 1); 
	ELSE
		SET `DeviceId`= '-1'; 
	END IF; 

	RETURN `DeviceId`; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function get_node_id
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_node_id`(
`AgentName` VARCHAR(32),
`NodeName` VARCHAR(32) ) RETURNS int(11)
BEGIN
	DECLARE `NodeId` INT DEFAULT '-1'; 
	DECLARE `NumberOfNodes` INT DEFAULT '0'; 

	SET `NumberOfNodes` = (SELECT COUNT(`node`.`id`) 
						FROM `node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`agent`.`id` = `node`.`agent_id`))); 

	IF (`NumberOfNodes` > '0') THEN
		SET `NodeId` = (SELECT `node`.`id` 
						FROM `node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`agent`.`id` = `node`.`agent_id`))
						ORDER BY `node`.`id` DESC
						LIMIT 1); 
	ELSE
		SET `NodeId`= '-1'; 
	END IF; 

	RETURN `NodeId`; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function get_variable_id
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_variable_id`(
`AgentName` VARCHAR(32),
`NodeName` VARCHAR(32),
`DeviceName` VARCHAR(32),
`VariableName` VARCHAR(32)) RETURNS int(11)
BEGIN
	DECLARE `VariableId` INT DEFAULT '-1'; 
	DECLARE `NumberOfVariables` INT; 

	SET `NumberOfVariables` = (SELECT COUNT(`variable`.`id`) 
						FROM `variable`,`device`,`node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`device`.`name` = `DeviceName`) AND
								(`variable`.`name` = `variableName`) AND
								(`agent`.`id` = `node`.`agent_id`) AND 
								(`node`.`id` = `device`.`node_id`) AND 
								(`device`.`id` = `variable`.`device_id`))); 

	IF (`NumberOfVariables` > '0') THEN
		SET `VariableId` = (SELECT `variable`.`id` 
						FROM `variable`,`device`,`node`,`agent`
						WHERE ((`agent`.`name` = `AgentName`) AND
								(`node`.`name` = `NodeName`) AND 
								(`device`.`name` = `DeviceName`) AND
								(`variable`.`name` = `variableName`) AND
								(`agent`.`id` = `node`.`agent_id`) AND 
								(`node`.`id` = `device`.`node_id`) AND 
								(`device`.`id` = `variable`.`device_id`))
						ORDER BY `variable`.`id` DESC
						LIMIT 1); 
	ELSE
		SET `VariableId`= '-1'; 
	END IF; 

	RETURN `VariableId`; 
END$$

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

