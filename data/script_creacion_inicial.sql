USE GD1C2024;
GO

-------- Setup --------

---- Drop constraints ----
DECLARE @drop_constraints NVARCHAR(max) = ''
SELECT @drop_constraints += 'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.'
                        +  QUOTENAME(OBJECT_NAME(parent_object_id)) + ' ' + 'DROP CONSTRAINT' + QUOTENAME(name)
FROM sys.foreign_keys f

EXEC sp_executesql @drop_constraints;
GO
----

---- Drop tablas ----
declare @drop_tablas NVARCHAR(max) = ''
SELECT @drop_tablas += 'DROP TABLE DASE_DE_BATOS.' + QUOTENAME(TABLE_NAME)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DASE_DE_BATOS' and TABLE_TYPE = 'BASE TABLE'

EXEC sp_executesql @drop_tablas;
GO
----

---- Drop procedures ----
DECLARE @drop_procedures NVARCHAR(max) = ''
SELECT @drop_procedures += 'DROP PROCEDURE DASE_DE_BATOS.' + QUOTENAME(NAME)
FROM sys.procedures
WHERE schema_id = SCHEMA_ID('DASE_DE_BATOS')

EXEC sp_executesql @drop_procedures;
GO
----

---- Drop schema ----
IF EXISTS (SELECT name FROM sys.schemas WHERE name = 'DASE_DE_BATOS')
	DROP SCHEMA DASE_DE_BATOS;
GO
----

---- Create schema ----
CREATE SCHEMA DASE_DE_BATOS
GO
----

---- Create tablas y constraints (~200ms) ----
CREATE TABLE DASE_DE_BATOS.PROVINCIAS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NOMBRE nvarchar(255) not null
);

CREATE TABLE DASE_DE_BATOS.LOCALIDADES (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NOMBRE nvarchar(255) not null,
	PROVINCIA_ID decimal(18, 0) not null,
	CONSTRAINT FK_LOCALIDAD_PROVINCIA FOREIGN KEY (PROVINCIA_ID) REFERENCES DASE_DE_BATOS.PROVINCIAS(ID)
);

CREATE TABLE DASE_DE_BATOS.SUCURSALES (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NOMBRE nvarchar(255) not null,
	DIRECCION nvarchar(255) not null,
	LOCALIDAD_ID decimal(18, 0) not null,
	CONSTRAINT FK_SUCURSAL_LOCALIDAD FOREIGN KEY (LOCALIDAD_ID) REFERENCES DASE_DE_BATOS.LOCALIDADES(ID)
);

CREATE TABLE DASE_DE_BATOS.CAJA_TIPOS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	TIPO nvarchar(50) not null -- Envío, Prioridad, Rapida
);

CREATE TABLE DASE_DE_BATOS.CAJAS (
	NUMERO decimal(18, 0) PRIMARY KEY, -- m.CAJA_NUMERO
	TIPO_ID decimal(18, 0) not null,
	SUCURSAL_ID decimal(18, 0) not null,
	CONSTRAINT FK_CAJA_TIPO FOREIGN KEY (TIPO_ID) REFERENCES DASE_DE_BATOS.CAJA_TIPOS(ID),
	CONSTRAINT FK_CAJA_SUCURSAL FOREIGN KEY (SUCURSAL_ID) REFERENCES DASE_DE_BATOS.SUCURSALES(ID)
);

CREATE TABLE DASE_DE_BATOS.EMPLEADOS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	DNI nvarchar(255) not null,
	NOMBRE nvarchar(255) not null,
	APELLIDO nvarchar(255) not null,
	MAIL nvarchar(255) not null,
	TELEFONO decimal(18, 0) not null,
	FECHA_REGISTRO datetime not null,
	FECHA_NACIMIENTO date not null,
	SUCURSAL_ID decimal(18, 0) not null,
	CONSTRAINT FK_EMPLEADO_SUCURSAL FOREIGN KEY (SUCURSAL_ID) REFERENCES DASE_DE_BATOS.SUCURSALES(ID)
);

CREATE TABLE DASE_DE_BATOS.COMPROBANTE_TIPOS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	TIPO nvarchar(50) not null -- A, B, C
);

CREATE TABLE DASE_DE_BATOS.VENTAS (
	NUMERO decimal(18, 0) PRIMARY KEY, -- m.TICKET_NUMERO
	FECHA_HORA datetime not null,
	NUMERO_CAJA decimal(18, 0) not null,
	EMPLEADO_ID decimal(18, 0) not null,
	TIPO_COMPROBANTE_ID decimal(18, 0) not null,
	CONSTRAINT FK_VENTA_CAJA FOREIGN KEY (NUMERO_CAJA) REFERENCES DASE_DE_BATOS.CAJAS(NUMERO),
	CONSTRAINT FK_VENTA_EMPLEADO FOREIGN KEY (EMPLEADO_ID) REFERENCES DASE_DE_BATOS.EMPLEADOS(ID),
	CONSTRAINT FK_VENTA_TIPO_COMPROBANTE FOREIGN KEY (TIPO_COMPROBANTE_ID) REFERENCES DASE_DE_BATOS.COMPROBANTE_TIPOS(ID)
);

CREATE TABLE DASE_DE_BATOS.CATEGORIAS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NOMBRE nvarchar(255) not null
);

CREATE TABLE DASE_DE_BATOS.SUBCATEGORIAS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NOMBRE nvarchar(255) not null,
	CATEGORIA_ID decimal(18, 0) not null,
	CONSTRAINT FK_SUBCATEGORIA_CATEGORIA FOREIGN KEY (CATEGORIA_ID) REFERENCES DASE_DE_BATOS.CATEGORIAS(ID)
);

CREATE TABLE DASE_DE_BATOS.MARCAS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NOMBRE nvarchar(255) not null
);

CREATE TABLE DASE_DE_BATOS.PRODUCTOS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NOMBRE nvarchar(255) not null,
	DESCRIPCION nvarchar(255) not null,
	SUBCATEGORIA_ID decimal(18, 0) not null,
	MARCA_ID decimal(18, 0) not null,
	CONSTRAINT FK_PRODUCTO_SUBCATEGORIA FOREIGN KEY (SUBCATEGORIA_ID) REFERENCES DASE_DE_BATOS.SUBCATEGORIAS(ID),
	CONSTRAINT FK_PRODUCTO_MARCA FOREIGN KEY (MARCA_ID) REFERENCES DASE_DE_BATOS.MARCAS(ID)
);

CREATE TABLE DASE_DE_BATOS.REGLAS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	DESCRIPCION nvarchar(255) not null,
	DESCUENTO decimal(18, 2) not null,
	CANTIDAD_MIN_PRODUCTOS decimal(18, 0) not null,
	CANTIDAD_PRODUCTOS_APLICADO decimal(18, 0) not null,
	MAX_USOS_X_VENTA decimal(18, 0) not null,
	MISMA_MARCA bit not null,
	MISMO_PRODUCTO bit not null
);

CREATE TABLE DASE_DE_BATOS.PROMOCIONES (
	CODIGO decimal(18, 0) PRIMARY KEY,
	DESCRIPCION nvarchar(255) not null,
	FECHA_INICIO datetime not null,
	FECHA_FIN datetime not null,
	REGLA_ID decimal(18, 0) not null,
	CONSTRAINT FK_PROMOCION_REGLA FOREIGN KEY (REGLA_ID) REFERENCES DASE_DE_BATOS.REGLAS(ID)
);

CREATE TABLE DASE_DE_BATOS.PRODUCTO_APLICABLE_PROMOCION (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	PRODUCTO_ID decimal(18, 0) not null,
	CODIGO_PROMOCION decimal(18, 0) not null,
	CONSTRAINT FK_PRODUCTO_APLICABLE_PROMOCION_PRODUCTO FOREIGN KEY (PRODUCTO_ID) REFERENCES DASE_DE_BATOS.PRODUCTOS(ID),
	CONSTRAINT FK_PRODUCTO_APLICABLE_PROMOCION_PROMOCION FOREIGN KEY (CODIGO_PROMOCION) REFERENCES DASE_DE_BATOS.PROMOCIONES(CODIGO)
);

CREATE TABLE DASE_DE_BATOS.ITEMS_VENTA (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NUMERO_VENTA decimal(18, 0) not null,
	PRODUCTO_ID decimal(18, 0) not null,
	PRECIO decimal(18, 2) not null,
	CANTIDAD decimal(18, 2) not null,
	CONSTRAINT FK_ITEM_VENTA_VENTA FOREIGN KEY (NUMERO_VENTA) REFERENCES DASE_DE_BATOS.VENTAS(NUMERO),
	CONSTRAINT FK_ITEM_VENTA_PRODUCTO FOREIGN KEY (PRODUCTO_ID) REFERENCES DASE_DE_BATOS.PRODUCTOS(ID)
);

CREATE TABLE DASE_DE_BATOS.ITEM_VENTA_PROMOCION (
	ITEM_ID decimal(18, 0) not null,
	PROMOCION_ID decimal(18, 0) not null,
	PRIMARY KEY (ITEM_ID, PROMOCION_ID),
	CONSTRAINT FK_ITEM_VENTA_PROMOCION_ITEM_VENTA FOREIGN KEY (ITEM_ID) REFERENCES DASE_DE_BATOS.ITEMS_VENTA(ID),
	CONSTRAINT FK_ITEM_VENTA_PROMOCION_PROMOCION FOREIGN KEY (PROMOCION_ID) REFERENCES DASE_DE_BATOS.PRODUCTO_APLICABLE_PROMOCION(ID)
);

CREATE TABLE DASE_DE_BATOS.CLIENTES (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	DNI nvarchar(255) not null,
	NOMBRE nvarchar(255) not null,
	APELLIDO nvarchar(255) not null,
	DOMICILIO nvarchar(255) not null,
	MAIL nvarchar(255) not null,
	TELEFONO decimal(18, 0) not null,
	FECHA_REGISTRO datetime not null,
	FECHA_NACIMIENTO date not null,
	LOCALIDAD_ID decimal(18, 0) not null,
	CONSTRAINT FK_CLIENTE_LOCALIDAD FOREIGN KEY (LOCALIDAD_ID) REFERENCES DASE_DE_BATOS.LOCALIDADES(ID)
);

CREATE TABLE DASE_DE_BATOS.ESTADOS_ENVIO (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	ESTADO nvarchar(50) -- Finalizado, NULL
);

CREATE TABLE DASE_DE_BATOS.ENVIOS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	FECHA_PROGRAMADA datetime not null,
	FECHA_HORA_ENTREGA datetime not null,
	HORARIO_INICIO decimal(18, 0) not null,
	HORARIO_FIN decimal(18, 0) not null,
	COSTO decimal(18, 2) not null,
	ESTADO_ENVIO_ID decimal(18, 0) not null,
	NUMERO_VENTA decimal(18, 0) not null,
	CLIENTE_ID decimal(18, 0) not null,
	CONSTRAINT FK_ENVIO_ESTADO FOREIGN KEY (ESTADO_ENVIO_ID) REFERENCES DASE_DE_BATOS.ESTADOS_ENVIO(ID),
	CONSTRAINT FK_ENVIO_VENTA FOREIGN KEY (NUMERO_VENTA) REFERENCES DASE_DE_BATOS.VENTAS(NUMERO),
	CONSTRAINT FK_ENVIO_CLIENTE FOREIGN KEY (CLIENTE_ID) REFERENCES DASE_DE_BATOS.CLIENTES(ID)
);

CREATE TABLE DASE_DE_BATOS.TIPOS_MEDIO_DE_PAGO (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	TIPO nvarchar(255) not null -- Ejectivo, Billetera Virtual, Tarjeta Crèdito, Tarjeta Debito
);

CREATE TABLE DASE_DE_BATOS.MEDIOS_DE_PAGO (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	NOMBRE nvarchar(50) not null,
	TIPO_MEDIO_PAGO_ID decimal(18, 0) not null,
	CONSTRAINT FK_MEDIO_DE_PAGO_TIPO_MEDIO_DE_PAGO FOREIGN KEY (TIPO_MEDIO_PAGO_ID) REFERENCES DASE_DE_BATOS.TIPOS_MEDIO_DE_PAGO(ID)
);

CREATE TABLE DASE_DE_BATOS.PAGOS (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	FECHA_HORA datetime not null,
	IMPORTE decimal(18, 2) not null,
	NUMERO_VENTA decimal(18, 0) not null,
	MEDIO_DE_PAGO_ID decimal(18, 0) not null,
	CONSTRAINT FK_PAGO_VENTA FOREIGN KEY (NUMERO_VENTA) REFERENCES DASE_DE_BATOS.VENTAS(NUMERO),
	CONSTRAINT FK_PAGO_MEDIO_DE_PAGO FOREIGN KEY (MEDIO_DE_PAGO_ID) REFERENCES DASE_DE_BATOS.MEDIOS_DE_PAGO(ID)
);

CREATE TABLE DASE_DE_BATOS.DETALLES_PAGO (
	PAGO_ID decimal(18, 0) not null,
	CLIENTE_ID decimal(18, 0) not null,
	NRO_TARJETA decimal(18, 0) not null,
	FECHA_VENCIMIENTO_TARJETA date not null,
	CUOTAS decimal(18, 0) not null,
	PRIMARY KEY (PAGO_ID, CLIENTE_ID),
	CONSTRAINT FK_DETALLE_PAGO_PAGO FOREIGN KEY (PAGO_ID) REFERENCES DASE_DE_BATOS.PAGOS(ID)
);

CREATE TABLE DASE_DE_BATOS.DESCUENTOS_MEDIO_DE_PAGO (
	ID decimal(18, 0) IDENTITY PRIMARY KEY,
	DESCRIPCION nvarchar(255) not null,
	FECHA_INICIO datetime not null,
	FECHA_FIN datetime not null,
	DESCUENTO decimal(18, 2) not null,
	TOPE decimal(18, 2) not null,
	MEDIO_DE_PAGO_ID decimal(18, 0) not null,
	CONSTRAINT FK_DESCUENTO_MEDIO_DE_PAGO_MEDIO_DE_PAGO FOREIGN KEY (MEDIO_DE_PAGO_ID) REFERENCES DASE_DE_BATOS.MEDIOS_DE_PAGO(ID)
);

CREATE TABLE DASE_DE_BATOS.PAGO_DESCUENTO (
	DESCUENTO_ID decimal(18, 0) not null,
	PAGO_ID decimal(18, 0) not null,
	PRIMARY KEY (DESCUENTO_ID, PAGO_ID),
	CONSTRAINT FK_PAGO_DESCUENTO_PAGO FOREIGN KEY (PAGO_ID) REFERENCES DASE_DE_BATOS.PAGOS(ID),
	CONSTRAINT FK_PAGO_DESCUENTO_DESCUENTO_MEDIO_DE_PAGO FOREIGN KEY (DESCUENTO_ID) REFERENCES DASE_DE_BATOS.DESCUENTOS_MEDIO_DE_PAGO(ID)
);
----

--------


-------- Migración --------

---- Create procedures ----
CREATE PROCEDURE DASE_DE_BATOS.SP_PROVINCIAS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.PROVINCIAS (NOMBRE)
		SELECT DISTINCT m.CLIENTE_PROVINCIA
		FROM gd_esquema.Maestra m
		WHERE m.CLIENTE_PROVINCIA IS NOT NULL

		UNION

		SELECT DISTINCT m.SUCURSAL_PROVINCIA
		FROM gd_esquema.Maestra m
		WHERE m.SUCURSAL_PROVINCIA IS NOT NULL

		UNION

		SELECT DISTINCT m.SUPER_PROVINCIA
		FROM gd_esquema.Maestra m
		WHERE m.SUPER_PROVINCIA IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_LOCALIDADES AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.LOCALIDADES (NOMBRE, PROVINCIA_ID)
		SELECT DISTINCT
		m.CLIENTE_LOCALIDAD,
		(
			SELECT TOP 1 p.ID
			FROM DASE_DE_BATOS.PROVINCIAS p
			WHERE p.NOMBRE = m.CLIENTE_PROVINCIA
		)
		FROM gd_esquema.Maestra m
		WHERE m.CLIENTE_LOCALIDAD IS NOT NULL

		UNION

		SELECT DISTINCT
		m.SUCURSAL_LOCALIDAD,
		(
			SELECT TOP 1 p.ID
			FROM DASE_DE_BATOS.PROVINCIAS p
			WHERE p.NOMBRE = m.SUCURSAL_PROVINCIA
		)
		FROM gd_esquema.Maestra m
		WHERE m.SUCURSAL_LOCALIDAD IS NOT NULL

		UNION

		SELECT DISTINCT
		m.SUPER_LOCALIDAD,
		(
			SELECT TOP 1 p.ID
			FROM DASE_DE_BATOS.PROVINCIAS p
			WHERE p.NOMBRE = m.SUPER_PROVINCIA
		)
		FROM gd_esquema.Maestra m
		WHERE m.SUPER_LOCALIDAD IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_SUCURSALES AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.SUCURSALES (NOMBRE, DIRECCION, LOCALIDAD_ID)
		SELECT DISTINCT
		m.SUCURSAL_NOMBRE,
		m.SUCURSAL_DIRECCION,
		(
			SELECT TOP 1 l.ID
			FROM DASE_DE_BATOS.LOCALIDADES l
			WHERE l.NOMBRE = m.SUCURSAL_LOCALIDAD
		)
		FROM gd_esquema.Maestra m
		WHERE m.SUCURSAL_NOMBRE IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_CAJA_TIPOS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.CAJA_TIPOS (TIPO)
		SELECT DISTINCT m.CAJA_TIPO
		FROM gd_esquema.Maestra m
		WHERE m.CAJA_TIPO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_CAJAS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.CAJAS (NUMERO, TIPO_ID, SUCURSAL_ID)
		SELECT DISTINCT
		m.CAJA_NUMERO,
		(
			SELECT TOP 1 ct.ID
			FROM DASE_DE_BATOS.CAJA_TIPOS ct
			WHERE ct.TIPO = m.CAJA_TIPO
		),
		(
			SELECT TOP 1 s.ID
			FROM DASE_DE_BATOS.SUCURSALES s
			WHERE s.NOMBRE = m.SUCURSAL_NOMBRE
		)
		FROM gd_esquema.Maestra m
		WHERE m.CAJA_TIPO IS NOT NULL AND m.SUCURSAL_NOMBRE IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_EMPLEADOS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.EMPLEADOS (DNI, NOMBRE, APELLIDO, MAIL, TELEFONO, FECHA_REGISTRO, FECHA_NACIMIENTO, SUCURSAL_ID)
		SELECT DISTINCT
		m.EMPLEADO_DNI,
		m.EMPLEADO_NOMBRE,
		m.EMPLEADO_APELLIDO,
		m.EMPLEADO_MAIL,
		m.EMPLEADO_TELEFONO,
		m.EMPLEADO_FECHA_REGISTRO,
		m.EMPLEADO_FECHA_NACIMIENTO,
		(
			SELECT TOP 1 s.ID
			FROM DASE_DE_BATOS.SUCURSALES s
			WHERE s.NOMBRE = m.SUCURSAL_NOMBRE
		)
		FROM gd_esquema.Maestra m
		WHERE m.EMPLEADO_DNI IS NOT NULL AND m.EMPLEADO_NOMBRE IS NOT NULL AND m.EMPLEADO_APELLIDO IS NOT NULL AND m.EMPLEADO_MAIL IS NOT NULL AND m.EMPLEADO_TELEFONO IS NOT NULL AND m.EMPLEADO_FECHA_REGISTRO IS NOT NULL AND m.EMPLEADO_FECHA_NACIMIENTO IS NOT NULL
		AND m.SUCURSAL_NOMBRE IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_COMPROBANTE_TIPOS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.COMPROBANTE_TIPOS (TIPO)
		SELECT DISTINCT m.TICKET_TIPO_COMPROBANTE
		FROM gd_esquema.Maestra m
		WHERE m.TICKET_TIPO_COMPROBANTE IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_VENTAS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.VENTAS (NUMERO, FECHA_HORA, NUMERO_CAJA, EMPLEADO_ID, TIPO_COMPROBANTE_ID)
		SELECT DISTINCT
			m.TICKET_NUMERO,
			m.TICKET_FECHA_HORA,
			m.CAJA_NUMERO,
			(
				SELECT TOP 1 e.ID
				FROM DASE_DE_BATOS.EMPLEADOS e
				WHERE e.DNI = m.EMPLEADO_DNI AND e.NOMBRE = m.EMPLEADO_NOMBRE AND e.APELLIDO = m.EMPLEADO_APELLIDO
			),
			(
				SELECT TOP 1 ct.ID
				FROM DASE_DE_BATOS.COMPROBANTE_TIPOS ct
				WHERE ct.TIPO = m.TICKET_TIPO_COMPROBANTE
			)
		FROM gd_esquema.Maestra m
		WHERE m.TICKET_NUMERO IS NOT NULL AND m.TICKET_FECHA_HORA IS NOT NULL AND m.CAJA_NUMERO IS NOT NULL AND m.EMPLEADO_DNI IS NOT NULL AND m.TICKET_TIPO_COMPROBANTE IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_CATEGORIAS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.CATEGORIAS (NOMBRE)
		SELECT DISTINCT m.PRODUCTO_CATEGORIA
		FROM gd_esquema.Maestra m
		WHERE m.PRODUCTO_CATEGORIA IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_SUBCATEGORIAS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.SUBCATEGORIAS (NOMBRE, CATEGORIA_ID)
		SELECT DISTINCT
		m.PRODUCTO_SUB_CATEGORIA,
		(
			SELECT TOP 1 c.ID
			FROM DASE_DE_BATOS.CATEGORIAS c
			WHERE c.NOMBRE = m.PRODUCTO_CATEGORIA
		)
		FROM gd_esquema.Maestra m
		WHERE m.PRODUCTO_SUB_CATEGORIA IS NOT NULL AND m.PRODUCTO_CATEGORIA IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_MARCAS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.MARCAS (NOMBRE)
		SELECT DISTINCT m.PRODUCTO_MARCA
		FROM gd_esquema.Maestra m
		WHERE m.PRODUCTO_MARCA IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_PRODUCTOS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.PRODUCTOS (NOMBRE, DESCRIPCION, SUBCATEGORIA_ID, MARCA_ID)
		SELECT DISTINCT
		m.PRODUCTO_NOMBRE,
		m.PRODUCTO_DESCRIPCION,
		(
			SELECT TOP 1 sc.ID
			FROM DASE_DE_BATOS.SUBCATEGORIAS sc
			WHERE sc.NOMBRE = m.PRODUCTO_SUB_CATEGORIA
		),
		(
			SELECT TOP 1 ma.ID
			FROM DASE_DE_BATOS.MARCAS ma
			WHERE ma.NOMBRE = m.PRODUCTO_MARCA
		)
		FROM gd_esquema.Maestra m
		WHERE m.PRODUCTO_NOMBRE IS NOT NULL AND m.PRODUCTO_DESCRIPCION IS NOT NULL AND m.PRODUCTO_SUB_CATEGORIA IS NOT NULL AND m.PRODUCTO_MARCA IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_REGLAS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.REGLAS (DESCRIPCION, DESCUENTO, CANTIDAD_MIN_PRODUCTOS, CANTIDAD_PRODUCTOS_APLICADO, MAX_USOS_X_VENTA, MISMA_MARCA, MISMO_PRODUCTO)
		SELECT DISTINCT
		m.REGLA_DESCRIPCION,
		m.REGLA_DESCUENTO_APLICABLE_PROD,
		m.REGLA_CANT_APLICABLE_REGLA,
		m.REGLA_CANT_APLICA_DESCUENTO,
		m.REGLA_CANT_MAX_PROD,
		CAST(
			CASE
				WHEN m.REGLA_APLICA_MISMA_MARCA IS NOT NULL THEN 1 ELSE 0
			END
		AS BIT),
		CAST(
			CASE
				WHEN m.REGLA_APLICA_MISMO_PROD IS NOT NULL THEN 1 ELSE 0
			END
		AS BIT)
		FROM gd_esquema.Maestra m
		WHERE m.REGLA_DESCRIPCION IS NOT NULL AND m.REGLA_DESCUENTO_APLICABLE_PROD IS NOT NULL AND m.REGLA_CANT_APLICABLE_REGLA IS NOT NULL AND m.REGLA_CANT_APLICA_DESCUENTO IS NOT NULL AND m.REGLA_CANT_MAX_PROD IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_PROMOCIONES AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.PROMOCIONES (CODIGO, DESCRIPCION, FECHA_INICIO, FECHA_FIN, REGLA_ID)
		SELECT DISTINCT
		m.PROMO_CODIGO,
		m.PROMOCION_DESCRIPCION,
		m.PROMOCION_FECHA_INICIO,
		m.PROMOCION_FECHA_FIN,
		(
			SELECT TOP 1 r.ID
			FROM DASE_DE_BATOS.REGLAS r
			WHERE r.DESCRIPCION = m.REGLA_DESCRIPCION AND r.DESCUENTO = m.REGLA_DESCUENTO_APLICABLE_PROD AND r.CANTIDAD_MIN_PRODUCTOS = m.REGLA_CANT_APLICABLE_REGLA AND r.CANTIDAD_PRODUCTOS_APLICADO = m.REGLA_CANT_APLICA_DESCUENTO AND r.MAX_USOS_X_VENTA = m.REGLA_CANT_MAX_PROD
		)
		FROM gd_esquema.Maestra m
		WHERE m.PROMO_CODIGO IS NOT NULL AND m.PROMOCION_DESCRIPCION IS NOT NULL AND m.PROMOCION_FECHA_INICIO IS NOT NULL AND m.PROMOCION_FECHA_FIN IS NOT NULL AND m.REGLA_DESCRIPCION IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_PRODUCTOS_APLICABLE_PROMOCION AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.PRODUCTO_APLICABLE_PROMOCION (PRODUCTO_ID, CODIGO_PROMOCION)
		SELECT DISTINCT
		(
			SELECT TOP 1 p.ID
			FROM DASE_DE_BATOS.PRODUCTOS p
			WHERE p.NOMBRE = m.PRODUCTO_NOMBRE AND p.DESCRIPCION = m.PRODUCTO_DESCRIPCION
		),
		m.PROMO_CODIGO
		FROM gd_esquema.Maestra m
		WHERE m.PRODUCTO_NOMBRE IS NOT NULL AND m.PRODUCTO_DESCRIPCION IS NOT NULL AND m.PROMO_CODIGO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_ITEMS_VENTA AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.ITEMS_VENTA (NUMERO_VENTA, PRODUCTO_ID, PRECIO, CANTIDAD)
		SELECT DISTINCT
		m.TICKET_NUMERO,
		(
			SELECT TOP 1 p.ID
			FROM DASE_DE_BATOS.PRODUCTOS p
			WHERE p.NOMBRE = m.PRODUCTO_NOMBRE AND p.DESCRIPCION = m.PRODUCTO_DESCRIPCION
		),
		m.PRODUCTO_PRECIO,
		m.TICKET_DET_CANTIDAD
		FROM gd_esquema.Maestra m
		WHERE m.TICKET_NUMERO IS NOT NULL AND m.PRODUCTO_PRECIO IS NOT NULL AND m.TICKET_DET_CANTIDAD IS NOT NULL
		AND m.PRODUCTO_NOMBRE IS NOT NULL AND m.PRODUCTO_DESCRIPCION IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_ITEM_VENTA_PROMOCION AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.ITEM_VENTA_PROMOCION (ITEM_ID, PROMOCION_ID)
		SELECT DISTINCT
		(
			SELECT TOP 1 iv.ID
			FROM DASE_DE_BATOS.ITEMS_VENTA iv
			JOIN DASE_DE_BATOS.PRODUCTOS p ON p.NOMBRE = m.PRODUCTO_NOMBRE AND p.DESCRIPCION = m.PRODUCTO_DESCRIPCION
			WHERE iv.NUMERO_VENTA = m.TICKET_NUMERO and iv.PRODUCTO_ID = p.ID
		),
		m.PROMO_CODIGO
		FROM gd_esquema.Maestra m
		WHERE m.PROMO_CODIGO IS NOT NULL AND m.TICKET_NUMERO IS NOT NULL AND m.PRODUCTO_NOMBRE IS NOT NULL AND m.PRODUCTO_DESCRIPCION IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_CLIENTES AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.CLIENTES (DNI, NOMBRE, APELLIDO, DOMICILIO, MAIL, TELEFONO, FECHA_REGISTRO, FECHA_NACIMIENTO, LOCALIDAD_ID)
		SELECT DISTINCT
		m.CLIENTE_DNI,
		m.CLIENTE_NOMBRE,
		m.CLIENTE_APELLIDO,
		m.CLIENTE_DOMICILIO,
		m.CLIENTE_MAIL,
		m.CLIENTE_TELEFONO,
		m.CLIENTE_FECHA_REGISTRO,
		m.CLIENTE_FECHA_NACIMIENTO,
		(
			SELECT TOP 1 l.ID
			FROM DASE_DE_BATOS.LOCALIDADES l
			WHERE l.NOMBRE = m.CLIENTE_LOCALIDAD
		)
		FROM gd_esquema.Maestra m
		WHERE m.CLIENTE_DNI IS NOT NULL AND m.CLIENTE_NOMBRE IS NOT NULL AND m.CLIENTE_APELLIDO IS NOT NULL AND m.CLIENTE_DOMICILIO IS NOT NULL AND m.CLIENTE_MAIL IS NOT NULL AND m.CLIENTE_TELEFONO IS NOT NULL AND m.CLIENTE_FECHA_REGISTRO IS NOT NULL AND m.CLIENTE_FECHA_NACIMIENTO IS NOT NULL AND m.CLIENTE_LOCALIDAD IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_ESTADOS_ENVIO AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.ESTADOS_ENVIO (ESTADO)
		SELECT DISTINCT m.ENVIO_ESTADO
		FROM gd_esquema.Maestra m
		WHERE m.ENVIO_ESTADO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_ENVIOS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.ENVIOS (FECHA_PROGRAMADA, FECHA_HORA_ENTREGA, HORARIO_INICIO, HORARIO_FIN, COSTO, ESTADO_ENVIO_ID, NUMERO_VENTA, CLIENTE_ID)
		SELECT DISTINCT
		m.ENVIO_FECHA_PROGRAMADA,
		m.ENVIO_FECHA_ENTREGA,
		m.ENVIO_HORA_INICIO,
		m.ENVIO_HORA_FIN,
		m.ENVIO_COSTO,
		(
			SELECT TOP 1 ee.ID
			FROM DASE_DE_BATOS.ESTADOS_ENVIO ee
			WHERE ee.ESTADO = m.ENVIO_ESTADO
		),
		m.TICKET_NUMERO,
		(
			SELECT TOP 1 c.ID
			FROM DASE_DE_BATOS.CLIENTES c
			WHERE c.DNI = m.CLIENTE_DNI AND c.NOMBRE = m.CLIENTE_NOMBRE AND c.APELLIDO = m.CLIENTE_APELLIDO
		)
		FROM gd_esquema.Maestra m
		WHERE m.ENVIO_FECHA_PROGRAMADA IS NOT NULL AND m.ENVIO_FECHA_ENTREGA IS NOT NULL AND m.ENVIO_HORA_INICIO IS NOT NULL AND m.ENVIO_HORA_FIN IS NOT NULL AND m.ENVIO_COSTO IS NOT NULL AND m.ENVIO_ESTADO IS NOT NULL AND m.TICKET_NUMERO IS NOT NULL AND m.CLIENTE_DNI IS NOT NULL AND m.CLIENTE_NOMBRE IS NOT NULL AND m.CLIENTE_APELLIDO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_TIPOS_MEDIO_DE_PAGO AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.TIPOS_MEDIO_DE_PAGO (TIPO)
		SELECT DISTINCT m.PAGO_TIPO_MEDIO_PAGO
		FROM gd_esquema.Maestra m
		WHERE m.PAGO_TIPO_MEDIO_PAGO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_MEDIOS_DE_PAGO AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.MEDIOS_DE_PAGO (NOMBRE, TIPO_MEDIO_PAGO_ID)
		SELECT DISTINCT
		m.PAGO_MEDIO_PAGO,
		(
			SELECT TOP 1 tmp.ID
			FROM DASE_DE_BATOS.TIPOS_MEDIO_DE_PAGO tmp
			WHERE tmp.TIPO = m.PAGO_TIPO_MEDIO_PAGO
		)
		FROM gd_esquema.Maestra m
		WHERE m.PAGO_MEDIO_PAGO IS NOT NULL AND m.PAGO_TIPO_MEDIO_PAGO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_PAGOS AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.PAGOS (FECHA_HORA, IMPORTE, NUMERO_VENTA, MEDIO_DE_PAGO_ID)
		SELECT DISTINCT
		m.PAGO_FECHA,
		m.PAGO_IMPORTE,
		m.TICKET_NUMERO,
		(
			SELECT TOP 1 mp.ID
			FROM DASE_DE_BATOS.MEDIOS_DE_PAGO mp
			WHERE mp.NOMBRE = m.PAGO_MEDIO_PAGO
		)
		FROM gd_esquema.Maestra m
		WHERE m.PAGO_FECHA IS NOT NULL AND m.PAGO_IMPORTE IS NOT NULL AND m.TICKET_NUMERO IS NOT NULL AND m.PAGO_MEDIO_PAGO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_DETALLES_PAGO AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.DETALLES_PAGO (PAGO_ID, CLIENTE_ID, NRO_TARJETA, FECHA_VENCIMIENTO_TARJETA, CUOTAS)
		SELECT DISTINCT
		(
			SELECT TOP 1 p.ID
			FROM DASE_DE_BATOS.PAGOS p
			WHERE p.FECHA_HORA = m.PAGO_FECHA AND p.IMPORTE = m.PAGO_IMPORTE AND p.NUMERO_VENTA = m.TICKET_NUMERO
		),
		(
			SELECT TOP 1 c.ID
			FROM DASE_DE_BATOS.CLIENTES c
			WHERE c.DNI = m.CLIENTE_DNI AND c.NOMBRE = m.CLIENTE_NOMBRE AND c.APELLIDO = m.CLIENTE_APELLIDO
		),
		m.PAGO_TARJETA_NRO,
		m.PAGO_TARJETA_FECHA_VENC,
		m.PAGO_TARJETA_CUOTAS
		FROM gd_esquema.Maestra m
		WHERE m.PAGO_FECHA IS NOT NULL AND m.PAGO_IMPORTE IS NOT NULL AND m.TICKET_NUMERO IS NOT NULL AND m.PAGO_TIPO_MEDIO_PAGO IS NOT NULL AND m.PAGO_TARJETA_NRO IS NOT NULL AND m.PAGO_TARJETA_FECHA_VENC IS NOT NULL AND m.PAGO_TARJETA_CUOTAS IS NOT NULL AND m.CLIENTE_DNI IS NOT NULL AND m.CLIENTE_NOMBRE IS NOT NULL AND m.CLIENTE_APELLIDO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_DESCUENTOS_MEDIO_DE_PAGO AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.DESCUENTOS_MEDIO_DE_PAGO (DESCRIPCION, FECHA_INICIO, FECHA_FIN, DESCUENTO, TOPE, MEDIO_DE_PAGO_ID)
		SELECT DISTINCT
		m.DESCUENTO_DESCRIPCION,
		m.DESCUENTO_FECHA_INICIO,
		m.DESCUENTO_FECHA_FIN,
		m.DESCUENTO_PORCENTAJE_DESC,
		m.DESCUENTO_TOPE,
		(
			SELECT TOP 1 mp.ID
			FROM DASE_DE_BATOS.MEDIOS_DE_PAGO mp
			WHERE mp.NOMBRE = m.PAGO_MEDIO_PAGO
		)
		FROM gd_esquema.Maestra m
		WHERE m.DESCUENTO_DESCRIPCION IS NOT NULL AND m.DESCUENTO_FECHA_INICIO IS NOT NULL AND m.DESCUENTO_FECHA_FIN IS NOT NULL AND m.DESCUENTO_PORCENTAJE_DESC IS NOT NULL AND m.DESCUENTO_TOPE IS NOT NULL
		AND m.PAGO_MEDIO_PAGO IS NOT NULL AND m.PAGO_TIPO_MEDIO_PAGO IS NOT NULL
	END
GO

CREATE PROCEDURE DASE_DE_BATOS.SP_PAGO_DESCUENTO AS
	BEGIN
	INSERT INTO DASE_DE_BATOS.PAGO_DESCUENTO (DESCUENTO_ID, PAGO_ID)
		SELECT DISTINCT
		(
			SELECT TOP 1 mp.ID
			FROM DASE_DE_BATOS.DESCUENTOS_MEDIO_DE_PAGO mp
			WHERE mp.DESCRIPCION = m.DESCUENTO_DESCRIPCION AND mp.FECHA_INICIO = m.DESCUENTO_FECHA_INICIO AND mp.FECHA_FIN = m.DESCUENTO_FECHA_FIN AND mp.DESCUENTO = m.DESCUENTO_PORCENTAJE_DESC AND mp.TOPE = m.DESCUENTO_TOPE
		),
		(
			SELECT TOP 1 p.ID
			FROM DASE_DE_BATOS.PAGOS p
			WHERE p.FECHA_HORA = m.PAGO_FECHA AND p.IMPORTE = m.PAGO_IMPORTE AND p.NUMERO_VENTA = m.TICKET_NUMERO
		)
		FROM gd_esquema.Maestra m
		WHERE m.DESCUENTO_DESCRIPCION IS NOT NULL AND m.DESCUENTO_FECHA_INICIO IS NOT NULL AND m.DESCUENTO_FECHA_FIN IS NOT NULL AND m.DESCUENTO_PORCENTAJE_DESC IS NOT NULL AND m.DESCUENTO_TOPE IS NOT NULL AND m.PAGO_FECHA IS NOT NULL AND m.PAGO_IMPORTE IS NOT NULL AND m.TICKET_NUMERO IS NOT NULL
	END
GO
----

---- Execute procedures ----
EXEC DASE_DE_BATOS.SP_PROVINCIAS
EXEC DASE_DE_BATOS.SP_LOCALIDADES
EXEC DASE_DE_BATOS.SP_SUCURSALES
EXEC DASE_DE_BATOS.SP_CAJA_TIPOS
EXEC DASE_DE_BATOS.SP_CAJAS
EXEC DASE_DE_BATOS.SP_EMPLEADOS
EXEC DASE_DE_BATOS.SP_COMPROBANTE_TIPOS
EXEC DASE_DE_BATOS.SP_VENTAS
EXEC DASE_DE_BATOS.SP_CATEGORIAS
EXEC DASE_DE_BATOS.SP_SUBCATEGORIAS
EXEC DASE_DE_BATOS.SP_MARCAS
EXEC DASE_DE_BATOS.SP_PRODUCTOS
EXEC DASE_DE_BATOS.SP_REGLAS
EXEC DASE_DE_BATOS.SP_PROMOCIONES
EXEC DASE_DE_BATOS.SP_PRODUCTOS_APLICABLE_PROMOCION
EXEC DASE_DE_BATOS.SP_ITEMS_VENTA
EXEC DASE_DE_BATOS.SP_ITEM_VENTA_PROMOCION
EXEC DASE_DE_BATOS.SP_CLIENTES
EXEC DASE_DE_BATOS.SP_ESTADOS_ENVIO
EXEC DASE_DE_BATOS.SP_ENVIOS
EXEC DASE_DE_BATOS.SP_MEDIOS_DE_PAGO
EXEC DASE_DE_BATOS.SP_PAGOS
EXEC DASE_DE_BATOS.SP_DETALLES_PAGO
EXEC DASE_DE_BATOS.SP_DESCUENTOS_MEDIO_DE_PAGO
EXEC DASE_DE_BATOS.SP_PAGO_DESCUENTO
----

--------
