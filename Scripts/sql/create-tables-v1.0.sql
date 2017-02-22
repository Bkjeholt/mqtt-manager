-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2016-12-01
-- Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-tables.js
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Table `agent`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `agent` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL,
  `ver` VARCHAR(16) NULL DEFAULT '---',
  `msg_version` VARCHAR(8) NOT NULL DEFAULT '1.0',
  `agent_state` ENUM('unknown', 'connected', 'timeout', 'non-validated') NOT NULL DEFAULT 'unknown',
  `agent_last_access` INT(11) NOT NULL DEFAULT '0' COMMENT 'Updated with current epoch time at every received message',
  `info` TEXT NULL DEFAULT NULL COMMENT 'Used for adding information about for example physical and logical location of the agent',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 26
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `calc`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `calc` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL,
  `type` VARCHAR(16) NOT NULL,
  `variable_id` INT(11) NOT NULL,
  `active` TINYINT(4) NOT NULL DEFAULT '0',
  `data_trans_key` VARCHAR(32) NOT NULL DEFAULT 'undefined-key' COMMENT 'A key value used to identify the transaction where the initial data was stored ',
  PRIMARY KEY (`id`),
  UNIQUE INDEX `Update` USING BTREE (`active` ASC, `id` ASC),
  UNIQUE INDEX `Namn` USING BTREE (`name` ASC))
ENGINE = InnoDB
AUTO_INCREMENT = 23
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `calc_input`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `calc_input` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `calc_id` INT(11) NOT NULL,
  `variable_id` INT(11) NOT NULL,
  `modified` INT(1) NULL DEFAULT '0',
  `modified_time` INT(11) NULL DEFAULT '0',
  `data_trans_key` VARCHAR(32) NULL DEFAULT 'Undefined transition key',
  PRIMARY KEY (`id`),
  INDEX `VariableIndex` USING BTREE (`variable_id` ASC, `calc_id` ASC))
ENGINE = InnoDB
AUTO_INCREMENT = 19
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `calc_param`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `calc_param` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `calc_id` INT(11) NOT NULL,
  `name` VARCHAR(16) NOT NULL,
  `value` VARCHAR(32) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `CreateLogicalCalcParam` (`calc_id` ASC, `name` ASC))
ENGINE = InnoDB
AUTO_INCREMENT = 25
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `data_bool`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `data_bool` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `variable_id` INT(11) NOT NULL,
  `time` INT(11) NOT NULL,
  `data` BINARY(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `index2` (`variable_id` ASC, `time` ASC))
ENGINE = InnoDB
AUTO_INCREMENT = 1186
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `data_float`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `data_float` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `variable_id` INT(11) NOT NULL,
  `time` INT(11) NOT NULL,
  `data` FLOAT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `index2` (`variable_id` ASC, `time` ASC))
ENGINE = InnoDB
AUTO_INCREMENT = 2074704
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `data_int`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `data_int` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `variable_id` INT(11) NOT NULL,
  `time` INT(11) NOT NULL,
  `data` INT(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `index2` (`variable_id` ASC, `time` ASC))
ENGINE = InnoDB
AUTO_INCREMENT = 370068
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `data_publish`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `data_publish` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `variable_id` INT(11) NOT NULL,
  `time` INT(11) NOT NULL,
  `published` INT(1) NOT NULL DEFAULT '0',
  `data` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `StoreIndex` USING BTREE (`variable_id` ASC, `time` ASC))
ENGINE = InnoDB
AUTO_INCREMENT = 109091
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `data_text`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `data_text` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `variable_id` INT(11) NOT NULL,
  `time` INT(11) NOT NULL,
  `data` TEXT NOT NULL,
  `error_code` INT(11) NOT NULL DEFAULT '0',
  `error_severity` ENUM('na', 'observation', 'warning', 'error') NOT NULL DEFAULT 'na',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 1446354
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `device`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `device` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(32) NULL DEFAULT NULL,
  `node_id` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 248
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `node`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `node` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL DEFAULT 'Not defined',
  `ver` VARCHAR(16) NOT NULL DEFAULT '---',
  `type` VARCHAR(16) NOT NULL DEFAULT '---',
  `agent_id` INT(11) NULL DEFAULT NULL,
  `timeout` INT(11) NOT NULL DEFAULT '600',
  `info` TEXT NULL DEFAULT NULL COMMENT 'Used for adding a description if the physical location of the node',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 144
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `variable`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `variable` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL,
  `primary` TINYINT(4) NOT NULL DEFAULT '1',
  `output` TINYINT(4) NOT NULL DEFAULT '0',
  `device_id` INT(11) NULL DEFAULT NULL,
  `data_type` ENUM('bool', 'int', 'float', 'text') NOT NULL DEFAULT 'text',
  `device_type` ENUM('dynamic', 'semistatic', 'static') NOT NULL DEFAULT 'dynamic',
  `wraparound` INT(11) NULL DEFAULT NULL COMMENT 'Wraparound value valid for accumulated type of devices.',
  `wraparound_offset` INT(11) NOT NULL DEFAULT '0' COMMENT 'Every time a wraparound occur, this value will be updated with the old figure plus the wraparound value and the data stored in the unitdata_float table will be the received value + this value.',
  `output_file_path` VARCHAR(120) NULL DEFAULT NULL,
  `data_coef` FLOAT NOT NULL DEFAULT '1',
  `data_offset` FLOAT NOT NULL DEFAULT '0',
  `retain` INT(11) NULL DEFAULT '0' COMMENT 'One ',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 240
DEFAULT CHARACTER SET = utf8;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

