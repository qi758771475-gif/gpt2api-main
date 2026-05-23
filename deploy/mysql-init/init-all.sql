CREATE TABLE IF NOT EXISTS `user` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid`            CHAR(36)        NOT NULL                  COMMENT '业务 ID',
  `email`           VARCHAR(128)    DEFAULT NULL,
  `phone`           VARCHAR(20)     DEFAULT NULL,
  `username`        VARCHAR(64)     DEFAULT NULL              COMMENT '昵称',
  `avatar`          VARCHAR(255)    DEFAULT NULL,
  `password`        VARCHAR(72)     NOT NULL                  COMMENT 'bcrypt',
  `points`          BIGINT          NOT NULL DEFAULT 0        COMMENT '可用点数 *100',
  `frozen_points`   BIGINT          NOT NULL DEFAULT 0        COMMENT '冻结点数 *100',
  `total_recharge`  BIGINT          NOT NULL DEFAULT 0        COMMENT '累计充值（分）',
  `plan_code`       VARCHAR(32)     NOT NULL DEFAULT 'free',
  `plan_expire_at`  DATETIME(3)     DEFAULT NULL,
  `inviter_id`      BIGINT UNSIGNED DEFAULT NULL,
  `invite_code`     VARCHAR(16)     NOT NULL,
  `status`          TINYINT         NOT NULL DEFAULT 1        COMMENT '1启用 0禁用 -1注销',
  `register_ip`     VARCHAR(45)     DEFAULT NULL,
  `last_login_at`   DATETIME(3)     DEFAULT NULL,
  `last_login_ip`   VARCHAR(45)     DEFAULT NULL,
  `created_at`      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)     DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_email` (`email`),
  UNIQUE KEY `uk_phone` (`phone`),
  UNIQUE KEY `uk_invite_code` (`invite_code`),
  KEY `idx_inviter` (`inviter_id`),
  KEY `idx_status_created` (`status`, `created_at`),
  KEY `idx_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户';

CREATE TABLE IF NOT EXISTS `user_profile` (
  `user_id`     BIGINT UNSIGNED NOT NULL,
  `gender`      TINYINT     DEFAULT 0,
  `birthday`    DATE        DEFAULT NULL,
  `bio`         VARCHAR(255) DEFAULT NULL,
  `prefer_lang` VARCHAR(10) DEFAULT 'zh-CN',
  `setting`     JSON        DEFAULT NULL,
  `updated_at`  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户扩展资料';

CREATE TABLE IF NOT EXISTS `user_invite_relation` (
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `inviter_id` BIGINT UNSIGNED NOT NULL,
  `invite_code` VARCHAR(16) NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`user_id`),
  KEY `idx_inviter` (`inviter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='邀请关系';


CREATE TABLE IF NOT EXISTS `admin_role` (
  `id`        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`      VARCHAR(64) NOT NULL,
  `code`      VARCHAR(32) NOT NULL,
  `remark`    VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='后台角色';

CREATE TABLE IF NOT EXISTS `admin_role_permission` (
  `role_id`     BIGINT UNSIGNED NOT NULL,
  `permission`  VARCHAR(128) NOT NULL,
  PRIMARY KEY (`role_id`, `permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='角色权限';

CREATE TABLE IF NOT EXISTS `admin_user` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username`   VARCHAR(64) NOT NULL,
  `password`   VARCHAR(72) NOT NULL,
  `nickname`   VARCHAR(64) DEFAULT NULL,
  `email`      VARCHAR(128) DEFAULT NULL,
  `role_id`    BIGINT UNSIGNED NOT NULL,
  `status`     TINYINT NOT NULL DEFAULT 1,
  `last_login_at` DATETIME(3) DEFAULT NULL,
  `last_login_ip` VARCHAR(45) DEFAULT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` DATETIME(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_role` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='后台账号';

CREATE TABLE IF NOT EXISTS `admin_audit_log` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_id`      BIGINT UNSIGNED NOT NULL,
  `admin_name`    VARCHAR(64) NOT NULL,
  `module`        VARCHAR(64) NOT NULL,
  `action`        VARCHAR(64) NOT NULL,
  `target_type`   VARCHAR(64) DEFAULT NULL,
  `target_id`     VARCHAR(64) DEFAULT NULL,
  `before_value`  JSON DEFAULT NULL,
  `after_value`   JSON DEFAULT NULL,
  `ip`            VARCHAR(45) DEFAULT NULL,
  `ua`            VARCHAR(255) DEFAULT NULL,
  `created_at`    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_admin` (`admin_id`),
  KEY `idx_module_action` (`module`, `action`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='后台操作审计';


CREATE TABLE IF NOT EXISTS `account` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `provider`       VARCHAR(32) NOT NULL                COMMENT 'gpt / grok',
  `name`           VARCHAR(128) NOT NULL,
  `auth_type`      VARCHAR(32) NOT NULL                COMMENT 'api_key / cookie / oauth',
  `credential_enc` BLOB NOT NULL                        COMMENT 'AES-256-GCM 加密',
  `base_url`       VARCHAR(255) DEFAULT NULL,
  `model_whitelist` JSON DEFAULT NULL,
  `weight`         INT NOT NULL DEFAULT 10,
  `rpm_limit`      INT NOT NULL DEFAULT 0,
  `tpm_limit`      INT NOT NULL DEFAULT 0,
  `daily_quota`    INT NOT NULL DEFAULT 0,
  `monthly_quota`  INT NOT NULL DEFAULT 0,
  `status`         TINYINT NOT NULL DEFAULT 1          COMMENT '1启用 0停用 2熔断 -1禁用',
  `cooldown_until` DATETIME(3) DEFAULT NULL,
  `last_used_at`   DATETIME(3) DEFAULT NULL,
  `last_error`     VARCHAR(255) DEFAULT NULL,
  `error_count`    INT NOT NULL DEFAULT 0,
  `success_count`  BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `remark`         VARCHAR(255) DEFAULT NULL,
  `created_by`     BIGINT UNSIGNED DEFAULT NULL,
  `created_at`     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`     DATETIME(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_provider_status` (`provider`, `status`),
  KEY `idx_status_cooldown` (`status`, `cooldown_until`),
  KEY `idx_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='第三方账号池';

CREATE TABLE IF NOT EXISTS `account_group` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `provider`   VARCHAR(32) NOT NULL,
  `code`       VARCHAR(64) NOT NULL,
  `name`       VARCHAR(128) NOT NULL,
  `strategy`   VARCHAR(32) NOT NULL DEFAULT 'round_robin',
  `status`     TINYINT NOT NULL DEFAULT 1,
  `remark`     VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` DATETIME(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_provider_code` (`provider`, `code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='账号池分组';

CREATE TABLE IF NOT EXISTS `account_group_member` (
  `group_id`   BIGINT UNSIGNED NOT NULL,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `weight`     INT NOT NULL DEFAULT 10,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`group_id`, `account_id`),
  KEY `idx_account` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='账号-分组成员';

CREATE TABLE IF NOT EXISTS `account_health` (
  `account_id`        BIGINT UNSIGNED NOT NULL,
  `last_check_at`     DATETIME(3) NOT NULL,
  `last_check_status` TINYINT NOT NULL,
  `consec_fail`       INT NOT NULL DEFAULT 0,
  `latency_ms_p50`    INT NOT NULL DEFAULT 0,
  `latency_ms_p99`    INT NOT NULL DEFAULT 0,
  `error_rate_1h`     DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `updated_at`        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='账号健康指标';


CREATE TABLE IF NOT EXISTS `api_key` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`      BIGINT UNSIGNED NOT NULL,
  `name`         VARCHAR(64) NOT NULL,
  `prefix`       VARCHAR(16) NOT NULL,
  `hash`         CHAR(64) NOT NULL                   COMMENT 'SHA256(key + salt)',
  `salt`         CHAR(32) NOT NULL,
  `last4`        CHAR(4) NOT NULL,
  `scope`        VARCHAR(255) NOT NULL DEFAULT 'image,video',
  `rpm_limit`    INT NOT NULL DEFAULT 60,
  `daily_quota`  INT NOT NULL DEFAULT 0,
  `expire_at`    DATETIME(3) DEFAULT NULL,
  `last_used_at` DATETIME(3) DEFAULT NULL,
  `status`       TINYINT NOT NULL DEFAULT 1,
  `created_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`   DATETIME(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_hash` (`hash`),
  KEY `idx_user_status` (`user_id`, `status`),
  KEY `idx_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户 API Key';


CREATE TABLE IF NOT EXISTS `model` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`         VARCHAR(64) NOT NULL,
  `name`         VARCHAR(128) NOT NULL,
  `kind`         VARCHAR(16) NOT NULL                COMMENT 'image / video',
  `provider`     VARCHAR(32) NOT NULL,
  `version`      VARCHAR(32) DEFAULT NULL,
  `tags`         VARCHAR(255) DEFAULT NULL,
  `cover_url`    VARCHAR(512) DEFAULT NULL,
  `description`  TEXT DEFAULT NULL,
  `point_per_unit` INT NOT NULL                      COMMENT '每张/每秒所需点数 *100',
  `unit`         VARCHAR(16) NOT NULL DEFAULT 'image',
  `default_params` JSON DEFAULT NULL,
  `group_code`   VARCHAR(64) NOT NULL                COMMENT '关联 account_group.code',
  `min_plan`     VARCHAR(32) NOT NULL DEFAULT 'free',
  `is_hot`       TINYINT NOT NULL DEFAULT 0,
  `is_new`       TINYINT NOT NULL DEFAULT 0,
  `sort`         INT NOT NULL DEFAULT 0,
  `status`       TINYINT NOT NULL DEFAULT 1,
  `created_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`   DATETIME(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_kind_status` (`kind`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='可用模型';

CREATE TABLE IF NOT EXISTS `plan` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`           VARCHAR(32) NOT NULL,
  `name`           VARCHAR(64) NOT NULL,
  `monthly_price`  BIGINT NOT NULL DEFAULT 0,
  `yearly_price`   BIGINT NOT NULL DEFAULT 0,
  `monthly_points` BIGINT NOT NULL DEFAULT 0,
  `rpm_limit`      INT NOT NULL DEFAULT 60,
  `concurrency`    INT NOT NULL DEFAULT 2,
  `model_scope`    JSON DEFAULT NULL,
  `feature`        JSON DEFAULT NULL,
  `status`         TINYINT NOT NULL DEFAULT 1,
  `sort`           INT NOT NULL DEFAULT 0,
  `created_at`     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='套餐';

CREATE TABLE IF NOT EXISTS `user_subscription` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `plan_code`  VARCHAR(32) NOT NULL,
  `start_at`   DATETIME(3) NOT NULL,
  `expire_at`  DATETIME(3) NOT NULL,
  `auto_renew` TINYINT NOT NULL DEFAULT 0,
  `source`     VARCHAR(32) NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_user_expire` (`user_id`, `expire_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户订阅';


CREATE TABLE IF NOT EXISTS `wallet_log` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `direction`     TINYINT NOT NULL                  COMMENT '1 收入 -1 支出',
  `biz_type`      VARCHAR(32) NOT NULL,
  `biz_id`        VARCHAR(64) NOT NULL,
  `points`        BIGINT NOT NULL,
  `points_before` BIGINT NOT NULL,
  `points_after`  BIGINT NOT NULL,
  `remark`        VARCHAR(255) DEFAULT NULL,
  `created_at`    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_user_created` (`user_id`, `created_at`),
  KEY `idx_biz` (`biz_type`, `biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='点数流水（总账）';

CREATE TABLE IF NOT EXISTS `recharge_record` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_no`      VARCHAR(32) NOT NULL,
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `channel`       VARCHAR(32) NOT NULL,
  `amount`        BIGINT NOT NULL                   COMMENT '分',
  `points`        BIGINT NOT NULL,
  `bonus_points`  BIGINT NOT NULL DEFAULT 0,
  `status`        TINYINT NOT NULL DEFAULT 0,
  `paid_at`       DATETIME(3) DEFAULT NULL,
  `channel_trade_no` VARCHAR(64) DEFAULT NULL,
  `client_ip`     VARCHAR(45) DEFAULT NULL,
  `extra`         JSON DEFAULT NULL,
  `created_at`    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_status` (`user_id`, `status`),
  KEY `idx_channel_trade` (`channel`, `channel_trade_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='充值记录';

CREATE TABLE IF NOT EXISTS `consume_record` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id`      CHAR(26) NOT NULL,
  `user_id`      BIGINT UNSIGNED NOT NULL,
  `kind`         VARCHAR(16) NOT NULL,
  `model_code`   VARCHAR(64) NOT NULL,
  `count`        INT NOT NULL,
  `unit_points`  BIGINT NOT NULL,
  `total_points` BIGINT NOT NULL,
  `status`       TINYINT NOT NULL                  COMMENT '0预扣 1成功 2退款',
  `account_id`   BIGINT UNSIGNED DEFAULT NULL,
  `created_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task` (`task_id`),
  KEY `idx_user_created` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='消费记录';

CREATE TABLE IF NOT EXISTS `refund_record` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id`    CHAR(26) NOT NULL,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `points`     BIGINT NOT NULL,
  `reason`     VARCHAR(255) NOT NULL,
  `operator`   VARCHAR(64) NOT NULL DEFAULT 'system',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='退款记录';


CREATE TABLE IF NOT EXISTS `promo_code` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`         VARCHAR(32) NOT NULL,
  `name`         VARCHAR(64) NOT NULL,
  `discount_type` TINYINT NOT NULL                COMMENT '1满减 2折扣 3赠点',
  `discount_val` BIGINT NOT NULL,
  `min_amount`   BIGINT NOT NULL DEFAULT 0,
  `apply_to`     VARCHAR(64) NOT NULL DEFAULT 'all',
  `total_qty`    INT NOT NULL DEFAULT 0,
  `used_qty`     INT NOT NULL DEFAULT 0,
  `per_user_limit` INT NOT NULL DEFAULT 1,
  `start_at`     DATETIME(3) NOT NULL,
  `end_at`       DATETIME(3) NOT NULL,
  `status`       TINYINT NOT NULL DEFAULT 1,
  `created_by`   BIGINT UNSIGNED DEFAULT NULL,
  `created_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_status_time` (`status`, `start_at`, `end_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='优惠码';

CREATE TABLE IF NOT EXISTS `promo_code_use` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `promo_id`   BIGINT UNSIGNED NOT NULL,
  `code`       VARCHAR(32) NOT NULL,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `order_no`   VARCHAR(32) DEFAULT NULL,
  `discount`   BIGINT NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_promo_user_order` (`promo_id`, `user_id`, `order_no`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='优惠码使用';

CREATE TABLE IF NOT EXISTS `redeem_code_batch` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `batch_no`     VARCHAR(32) NOT NULL,
  `name`         VARCHAR(64) NOT NULL,
  `reward_type`  VARCHAR(32) NOT NULL,
  `reward_value` JSON NOT NULL,
  `total_qty`    INT NOT NULL,
  `used_qty`     INT NOT NULL DEFAULT 0,
  `per_user_limit` INT NOT NULL DEFAULT 1,
  `expire_at`    DATETIME(3) DEFAULT NULL,
  `status`       TINYINT NOT NULL DEFAULT 1,
  `created_by`   BIGINT UNSIGNED DEFAULT NULL,
  `created_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_batch_no` (`batch_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='CDK 批次';

CREATE TABLE IF NOT EXISTS `redeem_code` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `batch_id`     BIGINT UNSIGNED NOT NULL,
  `code`         VARCHAR(32) NOT NULL,
  `status`       TINYINT NOT NULL DEFAULT 0        COMMENT '0未使用 1已使用 2作废',
  `used_by`      BIGINT UNSIGNED DEFAULT NULL,
  `used_at`      DATETIME(3) DEFAULT NULL,
  `created_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_batch_status` (`batch_id`, `status`),
  KEY `idx_used_by` (`used_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='CDK';

CREATE TABLE IF NOT EXISTS `invitation_reward` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `inviter_id` BIGINT UNSIGNED NOT NULL,
  `invitee_id` BIGINT UNSIGNED NOT NULL,
  `kind`       VARCHAR(32) NOT NULL,
  `points`     BIGINT NOT NULL,
  `from_order` VARCHAR(32) DEFAULT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_inviter_created` (`inviter_id`, `created_at`),
  KEY `idx_invitee` (`invitee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='邀请奖励';


CREATE TABLE IF NOT EXISTS `generation_task` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id`        CHAR(26) NOT NULL,
  `user_id`        BIGINT UNSIGNED NOT NULL,
  `kind`           VARCHAR(16) NOT NULL              COMMENT 'image / video',
  `mode`           VARCHAR(16) NOT NULL              COMMENT 't2i / i2i / t2v / i2v',
  `model_code`     VARCHAR(64) NOT NULL,
  `prompt`         TEXT NOT NULL,
  `neg_prompt`     TEXT DEFAULT NULL,
  `params`         JSON NOT NULL,
  `ref_assets`     JSON DEFAULT NULL,
  `count`          INT NOT NULL DEFAULT 1,
  `cost_points`    BIGINT NOT NULL,
  `idem_key`       VARCHAR(64) NOT NULL,
  `account_id`     BIGINT UNSIGNED DEFAULT NULL,
  `provider`       VARCHAR(32) NOT NULL,
  `status`         TINYINT NOT NULL DEFAULT 0        COMMENT '0待处理 1进行中 2成功 3失败 4已退点',
  `progress`       TINYINT NOT NULL DEFAULT 0,
  `error`          VARCHAR(255) DEFAULT NULL,
  `started_at`     DATETIME(3) DEFAULT NULL,
  `finished_at`    DATETIME(3) DEFAULT NULL,
  `client_ip`      VARCHAR(45) DEFAULT NULL,
  `from_api_key_id` BIGINT UNSIGNED DEFAULT NULL,
  `created_at`     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`     DATETIME(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  UNIQUE KEY `uk_user_idem` (`user_id`, `idem_key`),
  KEY `idx_user_kind_status` (`user_id`, `kind`, `status`),
  KEY `idx_status_created` (`status`, `created_at`),
  KEY `idx_account` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='生成任务';

CREATE TABLE IF NOT EXISTS `generation_result` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id`    CHAR(26) NOT NULL,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `kind`       VARCHAR(16) NOT NULL,
  `seq`        TINYINT NOT NULL DEFAULT 0,
  `url`        VARCHAR(512) NOT NULL,
  `thumb_url`  VARCHAR(512) DEFAULT NULL,
  `width`      INT DEFAULT NULL,
  `height`     INT DEFAULT NULL,
  `duration_ms` INT DEFAULT NULL,
  `size_bytes` BIGINT DEFAULT NULL,
  `meta`       JSON DEFAULT NULL,
  `is_public`  TINYINT NOT NULL DEFAULT 0,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `deleted_at` DATETIME(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_user_kind` (`user_id`, `kind`),
  KEY `idx_public_created` (`is_public`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='生成结果';

CREATE TABLE IF NOT EXISTS `prompt_history` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `kind`       VARCHAR(16) NOT NULL,
  `prompt`     TEXT NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_user_created` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='提示词历史';

CREATE TABLE IF NOT EXISTS `favorite` (
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `result_id`  BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`user_id`, `result_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='收藏';


CREATE TABLE IF NOT EXISTS `system_config` (
  `key`        VARCHAR(64) NOT NULL,
  `value`      JSON NOT NULL,
  `remark`     VARCHAR(255) DEFAULT NULL,
  `updated_by` BIGINT UNSIGNED DEFAULT NULL,
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='系统全局配置';

CREATE TABLE IF NOT EXISTS `system_dict` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `dict_group` VARCHAR(64) NOT NULL,
  `dict_key`   VARCHAR(64) NOT NULL,
  `dict_value` VARCHAR(255) NOT NULL,
  `sort`       INT NOT NULL DEFAULT 0,
  `status`     TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_key` (`dict_group`, `dict_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='系统字典';

CREATE TABLE IF NOT EXISTS `announcement` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title`      VARCHAR(128) NOT NULL,
  `content`    TEXT NOT NULL,
  `level`      VARCHAR(16) NOT NULL DEFAULT 'info',
  `start_at`   DATETIME(3) NOT NULL,
  `end_at`     DATETIME(3) NOT NULL,
  `status`     TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_status_time` (`status`, `start_at`, `end_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='公告';

CREATE TABLE IF NOT EXISTS `request_log` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `trace_id`     CHAR(36) NOT NULL,
  `user_id`      BIGINT UNSIGNED DEFAULT NULL,
  `api_key_id`   BIGINT UNSIGNED DEFAULT NULL,
  `method`       VARCHAR(8) NOT NULL,
  `path`         VARCHAR(255) NOT NULL,
  `status`       INT NOT NULL,
  `latency_ms`   INT NOT NULL,
  `client_ip`    VARCHAR(45) DEFAULT NULL,
  `ua`           VARCHAR(255) DEFAULT NULL,
  `req_size`     INT DEFAULT NULL,
  `resp_size`    INT DEFAULT NULL,
  `err_code`     INT DEFAULT NULL,
  `created_at`   DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`, `created_at`),
  KEY `idx_user_created` (`user_id`, `created_at`),
  KEY `idx_trace` (`trace_id`),
  KEY `idx_status_created` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='请求日志（按月分区）';

CREATE TABLE IF NOT EXISTS `pool_call_log` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id`    CHAR(26) NOT NULL,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `provider`   VARCHAR(32) NOT NULL,
  `endpoint`   VARCHAR(128) NOT NULL,
  `status`     INT NOT NULL,
  `latency_ms` INT NOT NULL,
  `tokens`     INT DEFAULT NULL,
  `error`      VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_account_created` (`account_id`, `created_at`),
  KEY `idx_status_created` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='账号池调用日志';



-- 1. 后台角色
INSERT INTO `admin_role` (`name`, `code`, `remark`) VALUES
  ('超级管理员', 'super', '拥有所有权限'),
  ('运营',      'ops',   '日常运营，无法管理超管'),
  ('客服',      'cs',    '只读 + 用户充值/退款'),
  ('风控',      'risk',  '封禁/解封/审计')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 1.1 默认超级管理员账号
-- 用户名: admin  密码: admin123 （bcrypt cost=12，请上线后立即在管理后台修改）
INSERT INTO `admin_user` (`username`, `password`, `nickname`, `role_id`, `status`)
SELECT 'admin',
       '$2a$12$4a8W/7ZL9nnFMnlwdXn2uOhkDYX53cnOUEovWnXs7XoA./alaTmeS',
       '系统管理员',
       (SELECT `id` FROM `admin_role` WHERE `code`='super' LIMIT 1),
       1
WHERE NOT EXISTS (SELECT 1 FROM `admin_user` WHERE `username`='admin');

-- 2. 套餐
INSERT INTO `plan` (`code`, `name`, `monthly_price`, `yearly_price`, `monthly_points`, `rpm_limit`, `concurrency`, `sort`)
VALUES
  ('free', '免费版', 0,    0,     10000,  30,  1, 1),
  ('pro',  'Pro',    2900, 29900, 100000, 120, 4, 2),
  ('max',  'Max',    9900, 99900, 500000, 300, 8, 3)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 3. 默认账号池分组
INSERT INTO `account_group` (`provider`, `code`, `name`, `strategy`)
VALUES
  ('gpt',  'gpt-image-default',   'GPT 通用生图', 'round_robin'),
  ('grok', 'grok-video-default',  'GROK 通用生视频', 'round_robin')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 4. 模型
INSERT INTO `model` (`code`, `name`, `kind`, `provider`, `version`, `tags`, `point_per_unit`, `unit`, `group_code`, `min_plan`, `is_hot`, `sort`)
VALUES
  ('img-v3',     '通用模型 V3.0', 'image', 'gpt',  'v3.0', '通用,写实,海报', 400, 'image',  'gpt-image-default',  'free', 1, 1),
  ('img-real',   '写实 V2.1',     'image', 'gpt',  'v2.1', '写实,人像,摄影', 400, 'image',  'gpt-image-default',  'free', 0, 2),
  ('img-anime',  '二次元 V2.0',   'image', 'gpt',  'v2.0', '二次元,漫画',     300, 'image',  'gpt-image-default',  'free', 1, 3),
  ('img-3d',     '3D 渲染 V2.0',  'image', 'gpt',  'v2.0', '3D,概念,渲染',    500, 'image',  'gpt-image-default',  'pro',  0, 4),
  ('vid-v1',     '文生视频 V1.0', 'video', 'grok', 'v1.0', '通用',            1500, 'second', 'grok-video-default', 'free', 1, 5),
  ('vid-i2v',    '图生视频 V1.0', 'video', 'grok', 'v1.0', '动画',            2000, 'second', 'grok-video-default', 'pro',  0, 6)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 5. 系统配置
INSERT INTO `system_config` (`key`, `value`, `remark`) VALUES
  ('points.cny_rate',     '100',                              '1 元 = N 点（最小单位 0.01）'),
  ('pool.strategy',       '"round_robin"',                    '调度策略'),
  ('pool.fail_threshold', '5',                                '熔断失败次数'),
  ('pool.cooldown_sec',   '600',                              '熔断冷却秒'),
  ('invite.first_recharge_reward', '5000',                    '首充返点（点 *100）'),
  ('invite.lifetime_share_pct',    '5',                       '终身分润 %')
ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);

-- 6. 字典
INSERT INTO `system_dict` (`dict_group`, `dict_key`, `dict_value`, `sort`) VALUES
  ('image_ratio', '1:1',   '正方形',  1),
  ('image_ratio', '3:4',   '竖版',    2),
  ('image_ratio', '4:3',   '横版',    3),
  ('image_ratio', '16:9',  '宽屏',    4),
  ('image_ratio', '9:16',  '手机壁纸', 5),
  ('video_dur',   '4',     '4 秒',    1),
  ('video_dur',   '8',     '8 秒',    2),
  ('video_dur',   '16',    '16 秒',   3)
ON DUPLICATE KEY UPDATE `dict_value`=VALUES(`dict_value`);




-- 代理（HTTP / HTTPS / SOCKS5）
CREATE TABLE IF NOT EXISTS `proxy` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(128) NOT NULL,
  `protocol`      VARCHAR(16)  NOT NULL                COMMENT 'http / https / socks5 / socks5h',
  `host`          VARCHAR(255) NOT NULL,
  `port`          INT UNSIGNED NOT NULL,
  `username`      VARCHAR(255) DEFAULT NULL,
  `password_enc`  BLOB         DEFAULT NULL            COMMENT 'AES-256-GCM 加密',
  `status`        TINYINT      NOT NULL DEFAULT 1      COMMENT '1启用 0停用',
  `last_check_at` DATETIME(3)  DEFAULT NULL,
  `last_check_ok` TINYINT      NOT NULL DEFAULT 0      COMMENT '0未知 1OK 2失败',
  `last_check_ms` INT          NOT NULL DEFAULT 0,
  `last_error`    VARCHAR(255) DEFAULT NULL,
  `remark`        VARCHAR(255) DEFAULT NULL,
  `created_by`    BIGINT UNSIGNED DEFAULT NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`    DATETIME(3)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='出站代理池';

-- account 表扩展：proxy_id + OAuth 元数据 + 测试结果
ALTER TABLE `account`
  ADD COLUMN `proxy_id`               BIGINT UNSIGNED DEFAULT NULL AFTER `base_url`,
  ADD COLUMN `oauth_meta`              JSON         DEFAULT NULL                            COMMENT '非敏感 OAuth 元数据：email / chatgpt_account_id / plan_type 等' AFTER `credential_enc`,
  ADD COLUMN `access_token_enc`        BLOB         DEFAULT NULL                            COMMENT 'AES-256-GCM 加密的 access_token',
  ADD COLUMN `refresh_token_enc`       BLOB         DEFAULT NULL                            COMMENT 'AES-256-GCM 加密的 refresh_token',
  ADD COLUMN `access_token_expires_at` DATETIME(3)  DEFAULT NULL                            COMMENT 'access_token 失效时间',
  ADD COLUMN `last_refresh_at`         DATETIME(3)  DEFAULT NULL                            COMMENT '最近一次成功刷新 RT 时间',
  ADD COLUMN `last_test_at`            DATETIME(3)  DEFAULT NULL                            COMMENT '最近一次连通性测试时间',
  ADD COLUMN `last_test_status`        TINYINT      NOT NULL DEFAULT 0                      COMMENT '0未测 1OK 2失败',
  ADD COLUMN `last_test_latency_ms`    INT          NOT NULL DEFAULT 0,
  ADD COLUMN `last_test_error`         VARCHAR(255) DEFAULT NULL,
  ADD KEY `idx_account_proxy` (`proxy_id`),
  ADD KEY `idx_account_token_exp` (`access_token_expires_at`);

-- 系统配置：代理 + OAuth 默认
INSERT INTO `system_config` (`key`, `value`, `remark`) VALUES
  ('proxy.global_enabled',          'false', '是否启用全局代理'),
  ('proxy.global_id',               '0',     '全局默认代理 ID（0 表示不使用）'),
  ('oauth.refresh_before_hours',    '6',     'access_token 距过期 N 小时内自动刷新'),
  ('oauth.openai_client_id',        '"app_EMoamEEZ73f0CkXaXp7hrann"', 'OpenAI Codex CLI 公开 client_id'),
  ('oauth.openai_token_url',        '"https://auth.openai.com/oauth/token"', 'OpenAI OAuth Token Endpoint')
ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);




ALTER TABLE `account`
  ADD COLUMN `session_token_enc` BLOB DEFAULT NULL COMMENT 'AES-GCM session_token（如 ST / id_token 存证）' AFTER `refresh_token_enc`;



ALTER TABLE `api_key`
  MODIFY COLUMN `scope` VARCHAR(255) NOT NULL DEFAULT 'chat,image,video';

UPDATE `api_key`
SET `scope` = 'chat,image,video'
WHERE `scope` = 'image,video';


INSERT INTO `account_group` (`provider`, `code`, `name`, `strategy`)
VALUES ('gpt', 'gpt-chat-default', 'GPT 通用文字', 'round_robin')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `model` (`code`, `name`, `kind`, `provider`, `version`, `tags`, `point_per_unit`, `unit`, `group_code`, `min_plan`, `is_hot`, `sort`)
VALUES ('gpt-4o-mini', '文字对话', 'text', 'gpt', 'chat', '文字,对话,兼容OpenAI', 100, '1k_token', 'gpt-chat-default', 'free', 1, 0)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `kind`=VALUES(`kind`), `provider`=VALUES(`provider`);

INSERT INTO `system_config` (`key`, `value`, `remark`)
SELECT 'billing.model_prices',
       '[{"model_code":"gpt-4o-mini","name":"文字对话","kind":"text","provider":"gpt","upstream_model":"gpt-4o-mini","unit_points":0,"input_unit_points":100,"output_unit_points":300,"enabled":true},{"model_code":"img-v3","name":"通用图片","kind":"image","provider":"gpt","upstream_model":"gpt-image","unit_points":400,"enabled":true},{"model_code":"img-real","name":"真实图片","kind":"image","provider":"gpt","upstream_model":"gpt-image-real","unit_points":400,"enabled":true},{"model_code":"img-anime","name":"动漫图片","kind":"image","provider":"gpt","upstream_model":"gpt-image-anime","unit_points":300,"enabled":true},{"model_code":"img-3d","name":"3D 图片","kind":"image","provider":"gpt","upstream_model":"gpt-image-3d","unit_points":500,"enabled":true},{"model_code":"vid-v1","name":"视频生成","kind":"video","provider":"grok","upstream_model":"grok-video","unit_points":1500,"enabled":true},{"model_code":"vid-i2v","name":"图生视频","kind":"video","provider":"grok","upstream_model":"grok-i2v","unit_points":2000,"enabled":true}]',
       '模型价格、上游映射和文字 token 计费'
WHERE NOT EXISTS (SELECT 1 FROM `system_config` WHERE `key`='billing.model_prices');


INSERT INTO `account_group` (`provider`, `code`, `name`, `strategy`)
VALUES ('grok', 'grok-web-default', 'Grok Web 账号池', 'round_robin')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `model` (`code`, `name`, `kind`, `provider`, `version`, `tags`, `point_per_unit`, `unit`, `group_code`, `min_plan`, `is_hot`, `sort`)
VALUES
('grok-4.20-fast', 'Grok 4.20 Fast', 'text', 'grok', 'chat', '文字,对话,Grok', 100, '1k_token', 'grok-web-default', 'free', 1, 10),
('grok-4.20-auto', 'Grok 4.20 Auto', 'text', 'grok', 'chat', '文字,对话,Grok', 150, '1k_token', 'grok-web-default', 'free', 1, 11),
('grok-4.20-expert', 'Grok 4.20 Expert', 'text', 'grok', 'chat', '文字,对话,Grok', 200, '1k_token', 'grok-web-default', 'free', 0, 12),
('grok-4.20-heavy', 'Grok 4.20 Heavy', 'text', 'grok', 'chat', '文字,对话,Grok', 400, '1k_token', 'grok-web-default', 'free', 0, 13),
('grok-4.3-beta', 'Grok 4.3 Beta', 'text', 'grok', 'chat', '文字,对话,Grok', 300, '1k_token', 'grok-web-default', 'free', 0, 14),
('grok-imagine-video', 'Grok Imagine Video', 'video', 'grok', 'video', '文生视频,图生视频,多图生视频,Grok', 2000, 'video', 'grok-web-default', 'free', 1, 20)
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`), `kind`=VALUES(`kind`), `provider`=VALUES(`provider`), `version`=VALUES(`version`),
`tags`=VALUES(`tags`), `point_per_unit`=VALUES(`point_per_unit`), `unit`=VALUES(`unit`), `group_code`=VALUES(`group_code`);

INSERT INTO `system_config` (`key`, `value`, `remark`)
SELECT 'billing.model_prices',
       '[]',
       '模型价格、上游映射和文字 token 计费'
WHERE NOT EXISTS (SELECT 1 FROM `system_config` WHERE `key`='billing.model_prices');

UPDATE `system_config`
SET `value` = JSON_ARRAY_APPEND(CAST(`value` AS JSON), '$', CAST('{"model_code":"grok-4.20-fast","name":"Grok 4.20 Fast","kind":"text","provider":"grok","upstream_model":"grok-4.20-fast","unit_points":0,"input_unit_points":100,"output_unit_points":300,"enabled":true}' AS JSON))
WHERE `key`='billing.model_prices' AND JSON_SEARCH(CAST(`value` AS JSON), 'one', 'grok-4.20-fast', NULL, '$[*].model_code') IS NULL;

UPDATE `system_config`
SET `value` = JSON_ARRAY_APPEND(CAST(`value` AS JSON), '$', CAST('{"model_code":"grok-4.20-auto","name":"Grok 4.20 Auto","kind":"text","provider":"grok","upstream_model":"grok-4.20-auto","unit_points":0,"input_unit_points":150,"output_unit_points":450,"enabled":true}' AS JSON))
WHERE `key`='billing.model_prices' AND JSON_SEARCH(CAST(`value` AS JSON), 'one', 'grok-4.20-auto', NULL, '$[*].model_code') IS NULL;

UPDATE `system_config`
SET `value` = JSON_ARRAY_APPEND(CAST(`value` AS JSON), '$', CAST('{"model_code":"grok-4.20-expert","name":"Grok 4.20 Expert","kind":"text","provider":"grok","upstream_model":"grok-4.20-expert","unit_points":0,"input_unit_points":200,"output_unit_points":600,"enabled":true}' AS JSON))
WHERE `key`='billing.model_prices' AND JSON_SEARCH(CAST(`value` AS JSON), 'one', 'grok-4.20-expert', NULL, '$[*].model_code') IS NULL;

UPDATE `system_config`
SET `value` = JSON_ARRAY_APPEND(CAST(`value` AS JSON), '$', CAST('{"model_code":"grok-4.20-heavy","name":"Grok 4.20 Heavy","kind":"text","provider":"grok","upstream_model":"grok-4.20-heavy","unit_points":0,"input_unit_points":400,"output_unit_points":1200,"enabled":true}' AS JSON))
WHERE `key`='billing.model_prices' AND JSON_SEARCH(CAST(`value` AS JSON), 'one', 'grok-4.20-heavy', NULL, '$[*].model_code') IS NULL;

UPDATE `system_config`
SET `value` = JSON_ARRAY_APPEND(CAST(`value` AS JSON), '$', CAST('{"model_code":"grok-4.3-beta","name":"Grok 4.3 Beta","kind":"text","provider":"grok","upstream_model":"grok-4.3-beta","unit_points":0,"input_unit_points":300,"output_unit_points":900,"enabled":true}' AS JSON))
WHERE `key`='billing.model_prices' AND JSON_SEARCH(CAST(`value` AS JSON), 'one', 'grok-4.3-beta', NULL, '$[*].model_code') IS NULL;

UPDATE `system_config`
SET `value` = JSON_ARRAY_APPEND(CAST(`value` AS JSON), '$', CAST('{"model_code":"grok-imagine-video","name":"Grok Imagine Video","kind":"video","provider":"grok","upstream_model":"grok-imagine-video","unit_points":2000,"enabled":true}' AS JSON))
WHERE `key`='billing.model_prices' AND JSON_SEARCH(CAST(`value` AS JSON), 'one', 'grok-imagine-video', NULL, '$[*].model_code') IS NULL;


-- 幂等：已存在 session_token_enc 时跳过。适用于早期数据卷未执行 20260428140000 的情况。
SET @__klein_stmt := (
  SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'account'
        AND COLUMN_NAME = 'session_token_enc') < 1,
    'ALTER TABLE `account` ADD COLUMN `session_token_enc` BLOB DEFAULT NULL COMMENT ''AES-GCM session / id_token''',
    'SELECT 1'
  )
);
PREPARE __klein_prep FROM @__klein_stmt;
EXECUTE __klein_prep;
DEALLOCATE PREPARE __klein_prep;


CREATE TABLE IF NOT EXISTS `generation_upstream_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `task_id` char(26) NOT NULL,
  `provider` varchar(32) NOT NULL,
  `account_id` bigint unsigned DEFAULT NULL,
  `stage` varchar(64) NOT NULL,
  `method` varchar(12) DEFAULT NULL,
  `url` varchar(512) DEFAULT NULL,
  `status_code` int NOT NULL DEFAULT 0,
  `duration_ms` bigint NOT NULL DEFAULT 0,
  `request_excerpt` mediumtext,
  `response_excerpt` mediumtext,
  `error` text,
  `meta` json DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='provider upstream diagnostics';

INSERT INTO `system_config` (`key`, `value`, `remark`) VALUES
  ('grok.cf.enabled', 'true', 'GROK Cloudflare cookie 自动刷新开关'),
  ('grok.cf.flaresolverr_url', '"http://flaresolverr:8191"', '内置 FlareSolverr 地址'),
  ('grok.cf.refresh_interval_seconds', '600', 'GROK CF cookie 刷新间隔'),
  ('grok.cf.timeout_seconds', '90', 'FlareSolverr 单次解题超时'),
  ('grok.cf.cookies', '""', '最近一次 FlareSolverr 获取的 Cookie'),
  ('grok.cf.clearance', '""', '最近一次 FlareSolverr 获取的 cf_clearance'),
  ('grok.cf.user_agent', '""', 'FlareSolverr 浏览器 User-Agent'),
  ('grok.cf.browser', '""', 'FlareSolverr 浏览器类型'),
  ('grok.cf.last_error', '""', '最近一次 FlareSolverr 刷新错误'),
  ('grok.cf.last_refresh_at', '0', '最近一次 FlareSolverr 成功刷新时间')
ON DUPLICATE KEY UPDATE `remark`=VALUES(`remark`);


