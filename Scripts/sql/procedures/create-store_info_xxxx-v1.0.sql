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

