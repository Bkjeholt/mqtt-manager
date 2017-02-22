-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2016-12-01
-- Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-functions.js
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
-- function get_calc_list
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_calc_list`(
		`ListCalcName` VARCHAR(32)) RETURNS text CHARSET latin1
BEGIN
	DECLARE `Result` TEXT; 

	DECLARE `CalcId` INT; 
	DECLARE `CalcName` VARCHAR(32); 
	DECLARE `CalcType` VARCHAR(16); 
	DECLARE `CalcActive` BOOL; 

	DECLARE `DstAgentName` VARCHAR(32); 
	DECLARE `DstNodeName` VARCHAR(32); 
	DECLARE `DstDeviceName` VARCHAR(32); 
	DECLARE `DstVariableName` VARCHAR(32); 

	DECLARE `FirstItem` BOOL DEFAULT TRUE; 

	DECLARE `Done` INT DEFAULT FALSE; 
    DECLARE `Cursor` CURSOR FOR
		SELECT 	`calc`.`id`,
				`calc`.`name`,
				`calc`.`type`,
				`calc`.`active`,
				`agent`.`name`,
				`node`.`name`,
				`device`.`name`,
				`variable`.`name`
			FROM `calc`,`agent`,`node`,`device`,`variable`
			WHERE ((`calc`.`name`= `ListCalcName`) OR (`ListCalcName` = '---')) AND
				  (`variable`.`id` = `calc`.`variable_id`) AND
				  (`device`.`id` = `variable`.`device_id`) AND
				  (`node`.`id` = `device`.`node_id`) AND
				  (`agent`.`id` = `node`.`agent_id`)
		ORDER BY `calc`.`name` ASC; 

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

	OPEN `Cursor`; 

	SET `Result` = '['; 
	
	read_loop_get_calc: LOOP
		FETCH `Cursor`
			INTO `CalcId`,`CalcName`,`CalcType`,`CalcActive`,`DstAgentName`,`DstNodeName`,`DstDeviceName`,`DstVariableName`; 
    
		IF (`Done`) THEN
			SET `Result` = CONCAT(`Result`,']'); 
			
			LEAVE read_loop_get_calc; 
		END IF; 

		IF (`FirstItem` = FALSE) THEN
			SET `Result` = CONCAT(`Result`,','); 
		END IF; 

		SET `FirstItem` = FALSE; 

		SET `Result` = CONCAT(`Result`,'{name:"',`CalcName`,'",type:"',`CalcType`,'",active:"',`CalcActive`,'",',
									   'dst: {agent:"',`DstAgentName`,'",node:"',`DstNodeName`,'",device:"',`DstDeviceName`,'",variable:"',`DstVariableName`,'"}'); 

		IF (`ListCalcName` = '---') THEN
			SET `Result` = CONCAT(`Result`,'}'); 
		ELSE
			get_list_of_input_variables: BEGIN
				DECLARE `AgentName` VARCHAR(32); 
				DECLARE `NodeName` VARCHAR(32); 
				DECLARE `DeviceName` VARCHAR(32); 
				DECLARE `VariableName` VARCHAR(32); 

				DECLARE `FirstItem` BOOL DEFAULT TRUE; 

				DECLARE `Done` INT DEFAULT FALSE; 
				DECLARE `Cursor` CURSOR FOR
				SELECT 	`agent`.`name`,
						`node`.`name`,
						`device`.`name`,
						`variable`.`name`
					FROM `calc_input`,`agent`,`node`,`device`,`variable`
					WHERE
						(`calc_input`.`calc_id` = `CalcId`) AND
						(`variable`.`id` = `calc_input`.`variable_id`) AND
						(`device`.`id` = `variable`.`device_id`) AND
						(`node`.`id` = `device`.`node_id`) AND
						(`agent`.`id` = `node`.`agent_id`)
					ORDER BY `agent`.`name` ASC, `node`.`name` ASC, `device`.`name` ASC, `variable`.`name` ASC; 

				DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

				OPEN `Cursor`; 

				SET `Result` = CONCAT(`Result`,', inputs:['); 

				read_loop_get_calc_input: LOOP
					FETCH `Cursor`
						INTO `AgentName`,`NodeName`,`DeviceName`,`VariableName`; 
		
					IF (`Done`) THEN
						SET `Result` = CONCAT(`Result`,']'); 
						LEAVE read_loop_get_calc_input; 
					END IF; 

					IF (`FirstItem` = FALSE) THEN
						SET `Result` = CONCAT(`Result`,','); 
					END IF; 

					SET `FirstItem` = FALSE; 
					SET `Result` = CONCAT(`Result`,'{agent:"',`AgentName`,'",node:"',`NodeName`,'",device:"',`DeviceName`,'",variable:"',`VariableName`,'"}'); 
		
				END LOOP read_loop_get_calc_input; 

			END get_list_of_input_variables; 

			SET `Result` = CONCAT(`Result`,'}'); 
		END IF; 

	END LOOP read_loop_get_calc; 

	SET `Result` = CONCAT(`Result`,']'); 

	RETURN `Result`; 
END$$

DELIMITER ;

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
			SET `Result` = CONCAT('{time:"',`DataTime`,'",'
				   'data:"',`DataValue`,'"}  '); 
		END IF; 
    END IF; 
    
	RETURN `Result`; 
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
-- function get_latest_variable_data
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_latest_variable_data`(
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

-- -----------------------------------------------------
-- function get_list_of_agents
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_list_of_agents`() RETURNS text CHARSET latin1
BEGIN
	DECLARE `result`TEXT; 

	DECLARE `Name` VARCHAR(32); 
	DECLARE `Revision` VARCHAR(16); 
	DECLARE `LastAccess` INT; 
	DECLARE `State` VARCHAR(16); 

	DECLARE `FirstUnit` INT DEFAULT TRUE; 

	DECLARE `done` INT DEFAULT FALSE; 
	DECLARE `cur` CURSOR FOR
		SELECT 	`agent`.`name`,
				`agent`.`ver`,
				`agent`.`agent_state`,
				`agent`.`agent_last_access`
			FROM `agent`
			ORDER BY `name` ASC; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = TRUE; 

	OPEN `cur`; 

	SET `result` = CONCAT('{name: "list-of-agents",',
						   'rev: "1.0",',
						   'agents: ['); 

	read_loop: LOOP
		FETCH `cur`INTO `Name`,`Revision`,`State`,`LastAccess`; 

		IF (`done`) THEN
			LEAVE read_loop; 
		END IF; 

		IF (`FirstUnit` != TRUE) THEN
			SET `result` = CONCAT(`result`,','); 
		ELSE
			SET `FirstUnit` = FALSE; 
		END IF; 
			
		SET `result` = CONCAT(`result`,
								'{last_access: "', FROM_UNIXTIME(`LastAccess`), '",',
								 'name: "', `Name`, '",',
								 'rev: "', `Revision`, '",',
								 'state: "', `State`, '"}'); 
	END LOOP; 

	SET `result` = CONCAT(`result`,']}'); 
	
RETURN `result`; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function get_list_of_devices
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_list_of_devices`(
		`AgentName` VARCHAR(32),
		`NodeName` VARCHAR(32)
	) RETURNS text CHARSET latin1
BEGIN
	DECLARE `result`TEXT; 

	DECLARE `Name` VARCHAR(32); 
	DECLARE `Revision` VARCHAR(16); 
	DECLARE `Type` VARCHAR(16); 

	DECLARE `FirstUnit` INT DEFAULT TRUE; 

	DECLARE `done` INT DEFAULT FALSE; 
	DECLARE `cur` CURSOR FOR
		SELECT 	`device`.`name`
			FROM `device`,`node`,`agent`
			WHERE	(`agent`.`name` = `AgentName`) AND
					(`node`.`name` = `NodeName`) AND
					(`agent`.`id` = `node`.`agent_id`) AND
					(`node`.`id` = `device`.`node_id`)
			ORDER BY `node`.`id` ASC; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = TRUE; 

	OPEN `cur`; 

	SET `result` = CONCAT('{name: "list-of-devices",',
						   'agent: "',`AgentName`,'",',
						   'node: "',`NodeName`,'",',
						   'rev: "1.0",',
						   'devices: ['); 

	read_loop: LOOP
		FETCH `cur`INTO `Name`; 

		IF (`done`) THEN
			LEAVE read_loop; 
		END IF; 

		IF (`FirstUnit` != TRUE) THEN
			SET `result` = CONCAT(`result`,','); 
		ELSE
			SET `FirstUnit` = FALSE; 
		END IF; 
			
		SET `result` = CONCAT(`result`,
								'{name: "', `Name`, '"}'); 
	END LOOP; 

	SET `result` = CONCAT(`result`,']'); 
	
RETURN `result`; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function get_list_of_nodes
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_list_of_nodes`(
		`AgentName` VARCHAR(32)
	) RETURNS text CHARSET latin1
BEGIN
	DECLARE `result`TEXT; 

	DECLARE `Name` VARCHAR(32); 
	DECLARE `Revision` VARCHAR(16); 
	DECLARE `Type` VARCHAR(16); 

	DECLARE `FirstUnit` INT DEFAULT TRUE; 

	DECLARE `done` INT DEFAULT FALSE; 
	DECLARE `cur` CURSOR FOR
		SELECT 	`node`.`name`,
				`node`.`ver`,
				`node`.`type`
			FROM `node`,`agent`
			WHERE	(`agent`.`name` = `AgentName`) AND
					(`agent`.`id` = `node`.`agent_id`)
			ORDER BY `node`.`id` ASC; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = TRUE; 

	OPEN `cur`; 

	SET `result` = CONCAT('{name: "list-of-nodes",',
						   'agent: "',`AgentName`,'",',
						   'rev: "1.0",',
						   'nodes: ['); 

	read_loop: LOOP
		FETCH `cur`INTO `Name`,`Revision`,`Type`; 

		IF (`done`) THEN
			LEAVE read_loop; 
		END IF; 

		IF (`FirstUnit` != TRUE) THEN
			SET `result` = CONCAT(`result`,','); 
		ELSE
			SET `FirstUnit` = FALSE; 
		END IF; 

		SET `result` = CONCAT(`result`,
								'{name: "', `Name`, '",',
								 'rev: "', `Revision`, '",',
								 'type: "', `Type`, '"}'); 
	END LOOP; 

	SET `result` = CONCAT(`result`,']}'); 
	
RETURN `result`; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function get_list_of_variables
-- -----------------------------------------------------

DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION `get_list_of_variables`(
		`AgentName` VARCHAR(32),
		`NodeName` VARCHAR(32),
		`DeviceName` VARCHAR(32)
	) RETURNS text CHARSET latin1
BEGIN
	DECLARE `result`TEXT; 

	DECLARE `Name` VARCHAR(32); 
	DECLARE `Primary` INT; 
	DECLARE `Output` INT; 
	DECLARE `DataType` VARCHAR(16); 
	DECLARE `DeviceType` VARCHAR(16); 
	DECLARE `WrapAround` INT; 
	DECLARE `WrapAroundOffset` INT; 
	DECLARE `DataCoef` FLOAT; 
	DECLARE `DataOffset` FLOAT; 

	DECLARE `FirstUnit` INT DEFAULT TRUE; 

	DECLARE `done` INT DEFAULT FALSE; 
	DECLARE `cur` CURSOR FOR
		SELECT 	`variable`.`name`,
				`variable`.`primary`,
				`variable`.`output`,
				`variable`.`data_type`,
				`variable`.`device_type`,
				`variable`.`wraparound`,
				`variable`.`wraparound_offset`,
				`variable`.`data_coef`,
				`variable`.`data_offset`
			FROM `variable`,`device`,`node`,`agent`
			WHERE	(`agent`.`name` = `AgentName`) AND
					(`node`.`name` = `NodeName`) AND
					(`device`.`name` = `DeviceName`) AND
					(`agent`.`id` = `node`.`agent_id`) AND
					(`node`.`id` = `device`.`node_id`) AND
					(`device`.`id` = `variable`.`device_id`)
			ORDER BY `variable`.`id` ASC; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = TRUE; 

	OPEN `cur`; 

	SET `result` = CONCAT('{name: "list-of-variables",',
						   'agent: "',`AgentName`,'",',
						   'node: "',`NodeName`,'",',
						   'device: "',`DeviceName`,'",',
						   'rev: "1.0",',
						   '{variables: ['); 

	read_loop: LOOP
		FETCH `cur`INTO `Name`,`Primary`,`Output`,`DataType`,`DeviceType`,`WrapAround`,`WrapAroundOffset`,`DataCoef`,`DataOffset`; 

		IF (`done`) THEN
			LEAVE read_loop; 
		END IF; 

		IF (`FirstUnit` != TRUE) THEN
			SET `result` = CONCAT(`result`,','); 
		ELSE
			SET `FirstUnit` = FALSE; 
		END IF; 
			
		SET `result` = CONCAT(`result`,
								'{name: "', `Name`, '",',
								'primary: "',`Primary`,'",',
								'output: "',`Output`,'",',
								'data_type: "',`DataType`,'",',
								'dev_type: "',`DeviceType`,'",',
								'wraparound: "',`WrapAround`,'",',
								'wraparound_offset: "',`WrapAroundOffset`,'",',
								'data_coef: "',`DataCoef`,'",',
								'data_offset: "',`DataOffset`,'"',
								'}'); 
	END LOOP; 

	SET `result` = CONCAT(`result`,']}'); 
	
RETURN `result`; 
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

