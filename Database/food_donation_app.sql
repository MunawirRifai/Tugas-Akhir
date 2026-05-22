-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 22, 2026 at 12:20 PM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `food_donation_app`
--

-- --------------------------------------------------------

--
-- Table structure for table `foods`
--

CREATE TABLE `foods` (
  `id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `food_name` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `quantity` int NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  `address` varchar(255) NOT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `expired_at` datetime NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `status` varchar(255) DEFAULT NULL,
  `claimed_by` bigint DEFAULT NULL,
  `claimed_quantity` int DEFAULT NULL,
  `original_quantity` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `is_verified` bit(1) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `phone` varchar(255) NOT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `verification_code` varchar(255) DEFAULT NULL,
  `verification_expired_at` datetime(6) DEFAULT NULL,
  `is_banned` bit(1) DEFAULT NULL,
  `role` varchar(255) DEFAULT NULL,
  `timeout_until` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `created_at`, `email`, `full_name`, `is_verified`, `password_hash`, `phone`, `photo_url`, `verification_code`, `verification_expired_at`, `is_banned`, `role`, `timeout_until`) VALUES
(10, '2026-04-09 08:05:26.864518', 'munawirr90@gmail.com', 'Munawir Rifa\'i', b'1', '$2y$10$3zLgcGT/DsBRtPXtPvdMuuo.GPXt4PqOmWOYMuE69ZLtAiU/tHtBO', '0822222222', 'http://localhost:8080/uploads/profile/1776512594302_IMG-20230925-WA0000.jpg', NULL, NULL, NULL, NULL, NULL),
(12, '2026-04-19 15:57:00.736582', 'gading@gmail.com', 'Gading mustiko', b'1', '$2a$10$kKdonjj8LOS.X6F8IeX2DOgbIK.hSQmfpAStOY.2n3B7pBO6G/V4O', '0800000000', 'http://localhost:8080/uploads/profile/0e7b61f2-10f1-46a4-abbc-b38d91f58637_gading.jpeg', NULL, NULL, NULL, NULL, NULL),
(33, '2026-05-15 18:19:33.569005', 'munawirr158@gmail.com', 'Munawir Rifa\'i', b'1', '$2a$10$Qt3iFSfBawavnxIogSTPJ.Ji2t8vvVIH6.bsBqaInDVOPBPBg3Gbi', '0888888888', NULL, NULL, NULL, NULL, NULL, NULL),
(34, '2026-05-15 18:32:23.660185', 'zil42231@gmail.com', 'Gading', b'1', '$2a$10$3wiSHmoCg/QlAEdLvz.xtePp5AQM9hgpD9/.ug3aofoTjiWY7uERy', '0877777777', NULL, NULL, NULL, NULL, NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `foods`
--
ALTER TABLE `foods`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_food_user` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `UK6dotkott2kjsp8vw4d0m25fb7` (`email`),
  ADD UNIQUE KEY `UKdu5v5sr43g5bfnji4vb8hg5s3` (`phone`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `foods`
--
ALTER TABLE `foods`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=620;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `foods`
--
ALTER TABLE `foods`
  ADD CONSTRAINT `fk_food_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
