-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2017-03-15
-- Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-calculates-vx.x.sql
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

CREATE PROCEDURE `calculate_modified_data`()
BEGIN
    DECLARE `DeviceId` INT; 
    DECLARE `SampleTime` INT; 
    DECLARE `CalcType` VARCHAR(16); 
    DECLARE `CalcInputModified` BOOL; 
    DECLARE `CalcTransactionKey` VARCHAR(32); 

    DECLARE `Done` INT DEFAULT FALSE; 
    DECLARE `Cursor` CURSOR FOR
        SELECT	`device`.`id` AS `DeviceId`,
				`device`.`calc_type` AS `CalcType`,
                `data_modified`.`time` AS `SampleTime`
			FROM `data_modified`,`device`,`calc_input`
            WHERE
				(`data_modified`.`variable_id` = `calc_input`.`variable_id`) AND
				(`device`.`id` = `calc_input`.`device_id`) AND
				(`device`.`calc_active` = TRUE)
			ORDER BY `data_modified`.`time` ASC, `data_modified`.`id` ASC; 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET `Done` = TRUE; 

	OPEN `Cursor`; 
    
	read_loop: LOOP
		FETCH `Cursor`
			INTO `DeviceId`,`CalcType`,`SampleTime`; 
    
		IF (`Done`) THEN
			LEAVE read_loop; 
		END IF; 

# 		UPDATE `calc` 
# 			SET `modified` = FALSE
# 			WHERE (`id` = `CalcId`); 

		CASE (`CalcType`)
			WHEN 'linear' THEN
				BEGIN
					CALL `__calc_linear`(`DeviceId`,`SampleTime`); 
				END; 
			WHEN 'min' THEN
				BEGIN
					CALL `__calc_min`(`CalcId`,`CalcTransactionKey`); 
				END; 
			WHEN 'power' THEN
				BEGIN
					CALL `__calc_power`(`CalcId`,`CalcTransactionKey`); 
				END; 
			WHEN 'avg' THEN
				BEGIN
					CALL `__calc_avg`(`CalcId`,`CalcTransactionKey`); 
				END; 
			WHEN 'min-ot' THEN
				BEGIN
					CALL `__calc_minfloat_ot`(`CalcId`,`CalcTransactionKey`); 
				END; 
			WHEN 'max-ot' THEN
				BEGIN
					CALL `__calc_maxfloat_ot`(`CalcId`,`CalcTransactionKey`); 
				END; 
			WHEN 'avg-ot' THEN
				BEGIN
					CALL `__calc_avgfloat_ot`(`CalcId`,`CalcTransactionKey`); 
				END; 
			ELSE
				BEGIN
					INSERT INTO `data_text`(`variable_id`,`time`,`data`)
						VALUES
							('-1',UNIX_TIMESTAMP(),
							 CONCAT('Error: Unsupported CalcType (CalcId/CalcName/CalcType)-> ',
						 `CalcId`,'/',`CalcName`,'/',`CalcType`)); 
				END; 
		END CASE; 
        
-- 		UPDATE `calc_input`
-- 			SET `modified` = FALSE
-- 			WHERE (`id` = (SELECT `id` 
-- 								FROM `calc_input` 
-- 								WHERE (`calc_id` = `CalcId`) 
-- 								LIMIT 1) ); 

    END LOOP; 
END$$


DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

