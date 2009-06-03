--
-- Table structure for table `others`
--

DROP TABLE IF EXISTS `others`;
CREATE TABLE `others` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `bar_code` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `others`
--


/*!40000 ALTER TABLE `others` DISABLE KEYS */;
LOCK TABLES `others` WRITE;
INSERT INTO `others` VALUES (1,'Ben',683,'2009-06-03 00:38:38','2009-06-03 00:38:38');
UNLOCK TABLES;
/*!40000 ALTER TABLE `others` ENABLE KEYS */;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `schema_migrations`
--


/*!40000 ALTER TABLE `schema_migrations` DISABLE KEYS */;
LOCK TABLES `schema_migrations` WRITE;
INSERT INTO `schema_migrations` VALUES ('20090603003750'),('20090603004214');
UNLOCK TABLES;
/*!40000 ALTER TABLE `schema_migrations` ENABLE KEYS */;

--
-- Table structure for table `somethings`
--

DROP TABLE IF EXISTS `somethings`;
CREATE TABLE `somethings` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `number` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `somethings`
--


/*!40000 ALTER TABLE `somethings` DISABLE KEYS */;
LOCK TABLES `somethings` WRITE;
INSERT INTO `somethings` VALUES (1,'useful',4,'2009-06-03 00:42:46','2009-06-03 00:42:46');
UNLOCK TABLES;
/*!40000 ALTER TABLE `somethings` ENABLE KEYS */;
