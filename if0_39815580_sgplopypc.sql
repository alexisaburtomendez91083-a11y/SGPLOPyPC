-- SGPLOPyPC - Esquema MariaDB compatible con Railway/phpMyAdmin
-- Charset recomendado para acentos y caracteres especiales

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `documento`;
DROP TABLE IF EXISTS `notificacion`;
DROP TABLE IF EXISTS `historial_cambio`;
DROP TABLE IF EXISTS `contrato`;
DROP TABLE IF EXISTS `evaluacion`;
DROP TABLE IF EXISTS `propuesta`;
DROP TABLE IF EXISTS `participacion`;
DROP TABLE IF EXISTS `fecha_proceso`;
DROP TABLE IF EXISTS `licitacion`;
DROP TABLE IF EXISTS `proveedor`;
DROP TABLE IF EXISTS `dependencia`;
DROP TABLE IF EXISTS `usuario`;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE `usuario` (
  `id_usuario` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(150) NOT NULL,
  `email` VARCHAR(200) NOT NULL,
  `contrasena_hash` VARCHAR(255) NOT NULL,
  `rol` ENUM('PUBLICO','PROVEEDOR','ADMINISTRADOR') NOT NULL,
  `activo` TINYINT(1) NOT NULL DEFAULT 1,
  `fecha_registro` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ultimo_acceso` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `uq_usuario_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `dependencia` (
  `id_dependencia` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(250) NOT NULL,
  `siglas` VARCHAR(20) DEFAULT NULL,
  `direccion` TEXT DEFAULT NULL,
  `telefono` VARCHAR(20) DEFAULT NULL,
  `email_contacto` VARCHAR(200) DEFAULT NULL,
  `activa` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_dependencia`),
  UNIQUE KEY `uq_dependencia_email_contacto` (`email_contacto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `proveedor` (
  `id_proveedor` INT NOT NULL AUTO_INCREMENT,
  `id_usuario` INT NOT NULL,
  `nombre_empresa` VARCHAR(250) NOT NULL,
  `representante_legal` VARCHAR(200) NOT NULL,
  `registro_fiscal` VARCHAR(20) NOT NULL,
  `domicilio` TEXT NOT NULL,
  `telefono` VARCHAR(20) DEFAULT NULL,
  `especialidad` VARCHAR(300) DEFAULT NULL,
  `estatus` ENUM('PENDIENTE','VALIDADO','RECHAZADO','SUSPENDIDO') NOT NULL DEFAULT 'PENDIENTE',
  `fecha_registro` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_proveedor`),
  UNIQUE KEY `uq_proveedor_usuario` (`id_usuario`),
  UNIQUE KEY `uq_proveedor_registro_fiscal` (`registro_fiscal`),
  CONSTRAINT `fk_proveedor_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `licitacion` (
  `id_licitacion` INT NOT NULL AUTO_INCREMENT,
  `numero_licitacion` VARCHAR(50) NOT NULL,
  `id_dependencia` INT NOT NULL,
  `id_usuario_responsable` INT NOT NULL,
  `tipo_procedimiento` ENUM('LICITACION_PUBLICA','INVITACION_RESTRINGIDA','ADJUDICACION_DIRECTA') NOT NULL,
  `descripcion_proyecto` TEXT NOT NULL,
  `presupuesto_estimado` DECIMAL(18,2) NOT NULL,
  `ubicacion_proyecto` VARCHAR(500) DEFAULT NULL,
  `estado_proceso` ENUM('BORRADOR','PUBLICADA','EN_ACLARACIONES','RECEPCION_PROPUESTAS','EN_EVALUACION','ADJUDICADA','DESIERTA','CANCELADA') NOT NULL DEFAULT 'BORRADOR',
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_licitacion`),
  UNIQUE KEY `uq_licitacion_numero` (`numero_licitacion`),
  KEY `idx_licitacion_estado` (`estado_proceso`),
  KEY `idx_licitacion_tipo` (`tipo_procedimiento`),
  KEY `idx_licitacion_dependencia` (`id_dependencia`),
  KEY `idx_licitacion_usuario` (`id_usuario_responsable`),
  CONSTRAINT `chk_licitacion_presupuesto_positivo` CHECK (`presupuesto_estimado` > 0),
  CONSTRAINT `fk_licitacion_dependencia`
    FOREIGN KEY (`id_dependencia`) REFERENCES `dependencia` (`id_dependencia`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT `fk_licitacion_usuario_responsable`
    FOREIGN KEY (`id_usuario_responsable`) REFERENCES `usuario` (`id_usuario`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `fecha_proceso` (
  `id_fecha_proceso` INT NOT NULL AUTO_INCREMENT,
  `id_licitacion` INT NOT NULL,
  `tipo_fecha` ENUM('PUBLICACION_CONVOCATORIA','JUNTA_ACLARACIONES','RECEPCION_PROPUESTAS','APERTURA_PROPUESTAS','FALLO_ADJUDICACION') NOT NULL,
  `fecha_programada` DATETIME NOT NULL,
  `fecha_real` DATETIME DEFAULT NULL,
  `observaciones` TEXT DEFAULT NULL,
  PRIMARY KEY (`id_fecha_proceso`),
  UNIQUE KEY `uq_fecha_proceso_licitacion_tipo` (`id_licitacion`,`tipo_fecha`),
  CONSTRAINT `fk_fecha_proceso_licitacion`
    FOREIGN KEY (`id_licitacion`) REFERENCES `licitacion` (`id_licitacion`)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `participacion` (
  `id_participacion` INT NOT NULL AUTO_INCREMENT,
  `id_proveedor` INT NOT NULL,
  `id_licitacion` INT NOT NULL,
  `fecha_inscripcion` DATETIME NOT NULL,
  `estatus` ENUM('INSCRITO','PROPUESTA_ENVIADA','DESCALIFICADO','GANADOR','NO_GANADOR') NOT NULL DEFAULT 'INSCRITO',
  PRIMARY KEY (`id_participacion`),
  UNIQUE KEY `uq_participacion_proveedor_licitacion` (`id_proveedor`,`id_licitacion`),
  KEY `idx_participacion_licitacion` (`id_licitacion`),
  KEY `idx_participacion_proveedor` (`id_proveedor`),
  CONSTRAINT `fk_participacion_proveedor`
    FOREIGN KEY (`id_proveedor`) REFERENCES `proveedor` (`id_proveedor`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT `fk_participacion_licitacion`
    FOREIGN KEY (`id_licitacion`) REFERENCES `licitacion` (`id_licitacion`)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `propuesta` (
  `id_propuesta` INT NOT NULL AUTO_INCREMENT,
  `id_participacion` INT NOT NULL,
  `monto_propuesta` DECIMAL(18,2) DEFAULT NULL,
  `descripcion_tecnica` TEXT DEFAULT NULL,
  `fecha_envio` DATETIME NOT NULL,
  `cumple_requisitos` TINYINT(1) DEFAULT NULL,
  `estatus` ENUM('RECIBIDA','EN_REVISION','ACEPTADA','RECHAZADA') NOT NULL DEFAULT 'RECIBIDA',
  PRIMARY KEY (`id_propuesta`),
  UNIQUE KEY `uq_propuesta_participacion` (`id_participacion`),
  CONSTRAINT `fk_propuesta_participacion`
    FOREIGN KEY (`id_participacion`) REFERENCES `participacion` (`id_participacion`)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `evaluacion` (
  `id_evaluacion` INT NOT NULL AUTO_INCREMENT,
  `id_propuesta` INT NOT NULL,
  `id_evaluador` INT NOT NULL,
  `puntaje_tecnico` DECIMAL(5,2) DEFAULT NULL,
  `puntaje_economico` DECIMAL(5,2) DEFAULT NULL,
  `puntaje_total` DECIMAL(5,2) DEFAULT NULL,
  `observaciones` TEXT DEFAULT NULL,
  `dictamen` ENUM('SOLVENTE','NO_SOLVENTE','DESCALIFICADA') DEFAULT NULL,
  `fecha_evaluacion` DATETIME NOT NULL,
  PRIMARY KEY (`id_evaluacion`),
  UNIQUE KEY `uq_evaluacion_propuesta` (`id_propuesta`),
  KEY `idx_evaluacion_usuario` (`id_evaluador`),
  CONSTRAINT `chk_evaluacion_puntaje_tecnico` CHECK (`puntaje_tecnico` IS NULL OR `puntaje_tecnico` >= 0),
  CONSTRAINT `chk_evaluacion_puntaje_economico` CHECK (`puntaje_economico` IS NULL OR `puntaje_economico` >= 0),
  CONSTRAINT `fk_evaluacion_propuesta`
    FOREIGN KEY (`id_propuesta`) REFERENCES `propuesta` (`id_propuesta`)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `fk_evaluacion_usuario`
    FOREIGN KEY (`id_evaluador`) REFERENCES `usuario` (`id_usuario`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contrato` (
  `id_contrato` INT NOT NULL AUTO_INCREMENT,
  `id_licitacion` INT NOT NULL,
  `id_proveedor` INT NOT NULL,
  `numero_contrato` VARCHAR(50) NOT NULL,
  `monto_contrato` DECIMAL(18,2) NOT NULL,
  `fecha_adjudicacion` DATE NOT NULL,
  `fecha_inicio` DATE DEFAULT NULL,
  `fecha_fin` DATE DEFAULT NULL,
  `estatus` ENUM('EN_FORMALIZACION','VIGENTE','EN_EJECUCION','CONCLUIDO','RESCINDIDO') NOT NULL DEFAULT 'EN_FORMALIZACION',
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_contrato`),
  UNIQUE KEY `uq_contrato_numero` (`numero_contrato`),
  UNIQUE KEY `uq_contrato_licitacion` (`id_licitacion`),
  KEY `idx_contrato_proveedor` (`id_proveedor`),
  CONSTRAINT `chk_contrato_monto_positivo` CHECK (`monto_contrato` > 0),
  CONSTRAINT `chk_contrato_fechas` CHECK (`fecha_fin` IS NULL OR `fecha_inicio` IS NULL OR `fecha_fin` >= `fecha_inicio`),
  CONSTRAINT `fk_contrato_licitacion`
    FOREIGN KEY (`id_licitacion`) REFERENCES `licitacion` (`id_licitacion`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT `fk_contrato_proveedor`
    FOREIGN KEY (`id_proveedor`) REFERENCES `proveedor` (`id_proveedor`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notificacion` (
  `id_notificacion` INT NOT NULL AUTO_INCREMENT,
  `id_usuario_destino` INT NOT NULL,
  `id_licitacion` INT DEFAULT NULL,
  `tipo_notificacion` ENUM('CONVOCATORIA_PUBLICADA','ACLARACION','RESULTADO_EVALUACION','ADJUDICACION','CAMBIO_ESTADO','GENERAL') NOT NULL,
  `titulo` VARCHAR(300) NOT NULL,
  `mensaje` TEXT NOT NULL,
  `leida` TINYINT(1) NOT NULL DEFAULT 0,
  `fecha_envio` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_lectura` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id_notificacion`),
  KEY `idx_notificacion_usuario` (`id_usuario_destino`),
  KEY `idx_notificacion_licitacion` (`id_licitacion`),
  KEY `idx_notificacion_usuario_leida` (`id_usuario_destino`,`leida`),
  CONSTRAINT `fk_notificacion_usuario_destino`
    FOREIGN KEY (`id_usuario_destino`) REFERENCES `usuario` (`id_usuario`)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `fk_notificacion_licitacion`
    FOREIGN KEY (`id_licitacion`) REFERENCES `licitacion` (`id_licitacion`)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `historial_cambio` (
  `id_historial` INT NOT NULL AUTO_INCREMENT,
  `id_usuario` INT NOT NULL,
  `tabla_afectada` VARCHAR(50) NOT NULL,
  `id_registro_afectado` INT NOT NULL,
  `accion` ENUM('CREAR','ACTUALIZAR','ELIMINAR') NOT NULL,
  `valores_anteriores` JSON DEFAULT NULL,
  `valores_nuevos` JSON DEFAULT NULL,
  `ip_origen` VARCHAR(45) DEFAULT NULL,
  `fecha_accion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_historial`),
  KEY `idx_historial_usuario` (`id_usuario`),
  KEY `idx_historial_tabla_registro` (`tabla_afectada`,`id_registro_afectado`),
  KEY `idx_historial_fecha_accion` (`fecha_accion`),
  CONSTRAINT `fk_historial_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `documento` (
  `id_documento` INT NOT NULL AUTO_INCREMENT,
  `nombre_archivo` VARCHAR(300) NOT NULL,
  `ruta_almacenamiento` VARCHAR(500) NOT NULL,
  `tipo_documento` ENUM('BASES_LICITACION','ANEXO_TECNICO','PLANO','FORMATO_OFICIAL','ACTA_PROCESO','PROPUESTA_TECNICA','PROPUESTA_ECONOMICA','DOC_COMPLEMENTARIA','DOC_LEGAL_PROVEEDOR','DOC_CONTRATO','ACLARACION','DICTAMEN') NOT NULL,
  `id_licitacion` INT DEFAULT NULL,
  `id_propuesta` INT DEFAULT NULL,
  `id_proveedor` INT DEFAULT NULL,
  `id_contrato` INT DEFAULT NULL,
  `id_evaluacion` INT DEFAULT NULL,
  `version` INT NOT NULL DEFAULT 1,
  `subido_por` INT NOT NULL,
  `fecha_subida` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tamano_bytes` BIGINT DEFAULT NULL,
  PRIMARY KEY (`id_documento`),
  KEY `idx_documento_tipo` (`tipo_documento`),
  KEY `idx_documento_licitacion` (`id_licitacion`),
  KEY `idx_documento_propuesta` (`id_propuesta`),
  KEY `idx_documento_proveedor` (`id_proveedor`),
  KEY `idx_documento_contrato` (`id_contrato`),
  KEY `idx_documento_evaluacion` (`id_evaluacion`),
  KEY `idx_documento_subido_por` (`subido_por`),
  CONSTRAINT `chk_documento_contexto` CHECK (
    `id_licitacion` IS NOT NULL OR
    `id_propuesta` IS NOT NULL OR
    `id_proveedor` IS NOT NULL OR
    `id_contrato` IS NOT NULL OR
    `id_evaluacion` IS NOT NULL
  ),
  CONSTRAINT `chk_documento_version` CHECK (`version` >= 1),
  CONSTRAINT `fk_documento_licitacion`
    FOREIGN KEY (`id_licitacion`) REFERENCES `licitacion` (`id_licitacion`)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT `fk_documento_propuesta`
    FOREIGN KEY (`id_propuesta`) REFERENCES `propuesta` (`id_propuesta`)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT `fk_documento_proveedor`
    FOREIGN KEY (`id_proveedor`) REFERENCES `proveedor` (`id_proveedor`)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT `fk_documento_contrato`
    FOREIGN KEY (`id_contrato`) REFERENCES `contrato` (`id_contrato`)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT `fk_documento_evaluacion`
    FOREIGN KEY (`id_evaluacion`) REFERENCES `evaluacion` (`id_evaluacion`)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT `fk_documento_usuario_subio`
    FOREIGN KEY (`subido_por`) REFERENCES `usuario` (`id_usuario`)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dato inicial de ejemplo (hash bcrypt)
INSERT INTO `usuario`
  (`id_usuario`, `nombre`, `email`, `contrasena_hash`, `rol`, `activo`, `fecha_registro`, `ultimo_acceso`)
VALUES
  (1, 'Joaquin Hernandez', 'joaqher@gmail.com', '$2y$12$WZc9ETANT.9znwHQR1/M7.P9y9aPcJayp5VcKMFxKFF8UPcP199LO', 'PUBLICO', 1, '2026-03-18 00:00:00', '2026-03-18 00:00:00')
ON DUPLICATE KEY UPDATE `email` = VALUES(`email`);
