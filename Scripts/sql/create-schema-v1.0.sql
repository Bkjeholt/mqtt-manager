-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2016-12-01
-- Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-schema.js
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema hic
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `hic` DEFAULT CHARACTER SET latin1 ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

