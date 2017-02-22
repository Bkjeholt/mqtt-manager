-- *************************************************************************
-- Product    : Home information and control
-- Date       : 2016-12-01
-- Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
-- Contact    : dev@kjeholt.se
-- Url        : http://www-dev.kjeholt.se
-- Licence    : ---
-- -------------------------------------------------------------------------
-- File       : create-views.js
-- Version    : 1.0
-- Author     : Bjorn Kjeholt
-- *************************************************************************

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- View `latest_data_bool`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `latest_data_bool`;

CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_bool` AS select from_unixtime(`data_bool`.`time`) AS `Time`,`data_bool`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_bool`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source` from `data_bool` order by `data_bool`.`time` desc;

-- -----------------------------------------------------
-- View `latest_data_float`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `latest_data_float`;

CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_float` AS select from_unixtime(`data_float`.`time`) AS `Time`,`data_float`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_float`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source`,`data_float`.`variable_id` AS `Variable id`,`data_float`.`time` AS `Epoch time` from `data_float` order by `data_float`.`time` desc limit 100;

-- -----------------------------------------------------
-- View `latest_data_int`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `latest_data_int`;

CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_int` AS select from_unixtime(`data_int`.`time`) AS `Time`,`data_int`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_int`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source`,`data_int`.`variable_id` AS `Variable id`,`data_int`.`time` AS `Epoch time` from `data_int` order by `data_int`.`time` desc limit 100;

-- -----------------------------------------------------
-- View `latest_data_text`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `latest_data_text`;

CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `latest_data_text` AS select from_unixtime(`data_text`.`time`) AS `Time`,`data_text`.`data` AS `Data`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_text`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `Source` from `data_text` order by from_unixtime(`data_text`.`time`) desc limit 1000;

-- -----------------------------------------------------
-- View `list_all_calc`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `list_all_calc`;

CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `list_all_calc` AS select `calc`.`name` AS `CalcName`,`calc_input`.`variable_id` AS `VarId` from (`calc` join `calc_input`) where (`calc`.`id` = `calc_input`.`calc_id`);

-- -----------------------------------------------------
-- View `list_all_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `list_all_info`;

CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `list_all_info` AS select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) AS `NameString`,`variable`.`id` AS `VariableId` from (((`agent` join `node`) join `device`) join `variable`) where ((`agent`.`id` = `node`.`agent_id`) and (`node`.`id` = `device`.`node_id`) and (`device`.`id` = `variable`.`device_id`)) order by `agent`.`id` desc,`node`.`id`,`device`.`id`,`variable`.`id`;

-- -----------------------------------------------------
-- View `list_all_unpublished_data`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `list_all_unpublished_data`;

CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `list_all_unpublished_data` AS select `data_publish`.`id` AS `DataPublishId`,`data_publish`.`variable_id` AS `VariableId`,`data_publish`.`time` AS `DataTime`,`data_publish`.`data` AS `DataValue`,(select concat(`agent`.`name`,'/',`node`.`name`,'/',convert(`device`.`name` using utf8),'/',`variable`.`name`) from (((`agent` join `node`) join `device`) join `variable`) where ((`variable`.`id` = `data_publish`.`variable_id`) and (`device`.`id` = `variable`.`device_id`) and (`node`.`id` = `device`.`node_id`) and (`agent`.`id` = `node`.`agent_id`)) limit 1) AS `TopicAddress`,concat('{"time":"',`data_publish`.`time`,'","data":"',`data_publish`.`data`,'"}') AS `Payload` from `data_publish` where (`data_publish`.`published` = 0) order by `data_publish`.`time`,`data_publish`.`id`;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

