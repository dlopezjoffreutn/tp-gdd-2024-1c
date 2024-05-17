USE GD1C2024;
GO

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

---- Create tablas y constraints ----

CREATE TABLE DASE_DE_BATOS.PROVINCIAS (
	ID decimal(18, 0) PRIMARY KEY,
	NOMBRE nvarchar(255) not null
);

CREATE TABLE DASE_DE_BATOS.LOCALIDADES (
	ID decimal(18, 0) PRIMARY KEY,
	NOMBRE nvarchar(255) not null,
	PROVINCIA_ID decimal(18, 0) not null,
	CONSTRAINT FK_LOCALIDAD_PROVINCIA FOREIGN KEY (PROVINCIA_ID) REFERENCES DASE_DE_BATOS.PROVINCIAS(ID)
);

CREATE TABLE DASE_DE_BATOS.SUCURSALES (
	ID decimal(18, 0) PRIMARY KEY,
	NOMBRE nvarchar(255) not null,
	DIRECCION nvarchar(255) not null,
	LOCALIDAD_ID decimal(18, 0) not null,
	CONSTRAINT FK_SUCURSAL_LOCALIDAD FOREIGN KEY (LOCALIDAD_ID) REFERENCES DASE_DE_BATOS.LOCALIDADES(ID)
);

CREATE TABLE DASE_DE_BATOS.CAJA_TIPOS (
	ID decimal(18, 0) PRIMARY KEY,
	TIPO nvarchar(50) not null -- Envío, Prioridad, Rapida
);

CREATE TABLE DASE_DE_BATOS.CAJAS (
	ID decimal(18, 0) PRIMARY KEY,
	TIPO_ID decimal(18, 0) not null,
	SUCURSAL_ID decimal(18, 0) not null,
	CONSTRAINT FK_CAJA_TIPO FOREIGN KEY (TIPO_ID) REFERENCES DASE_DE_BATOS.CAJA_TIPOS(ID),
	CONSTRAINT FK_CAJA_SUCURSAL FOREIGN KEY (SUCURSAL_ID) REFERENCES DASE_DE_BATOS.SUCURSALES(ID)
);

CREATE TABLE DASE_DE_BATOS.EMPLEADOS (
	ID decimal(18, 0) PRIMARY KEY,
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
	ID decimal(18, 0) PRIMARY KEY,
	TIPO nvarchar(50) not null -- A, B, C
);

CREATE TABLE DASE_DE_BATOS.VENTAS (
	ID decimal(18, 0) PRIMARY KEY,
	FECHA_HORA datetime not null,
	CAJA_ID decimal(18, 0) not null,
	EMPLEADO_ID decimal(18, 0) not null,
	TIPO_COMPROBANTE_ID decimal(18, 0) not null,
	CONSTRAINT FK_VENTA_CAJA FOREIGN KEY (CAJA_ID) REFERENCES DASE_DE_BATOS.CAJAS(ID),
	CONSTRAINT FK_VENTA_EMPLEADO FOREIGN KEY (EMPLEADO_ID) REFERENCES DASE_DE_BATOS.EMPLEADOS(ID),
	CONSTRAINT FK_VENTA_TIPO_COMPROBANTE FOREIGN KEY (TIPO_COMPROBANTE_ID) REFERENCES DASE_DE_BATOS.COMPROBANTE_TIPOS(ID)
);

CREATE TABLE DASE_DE_BATOS.CATEGORIAS (
	ID decimal(18, 0) PRIMARY KEY,
	NOMBRE nvarchar(255) not null
);

CREATE TABLE DASE_DE_BATOS.SUBCATEGORIAS (
	ID decimal(18, 0) PRIMARY KEY,
	NOMBRE nvarchar(255) not null,
	CATEGORIA_ID decimal(18, 0) not null,
	CONSTRAINT FK_SUBCATEGORIA_CATEGORIA FOREIGN KEY (CATEGORIA_ID) REFERENCES DASE_DE_BATOS.CATEGORIAS(ID)
);

CREATE TABLE DASE_DE_BATOS.MARCAS (
	ID decimal(18, 0) PRIMARY KEY,
	NOMBRE nvarchar(255) not null
);

CREATE TABLE DASE_DE_BATOS.PRODUCTOS (
	ID decimal(18, 0) PRIMARY KEY,
	NOMBRE nvarchar(255) not null,
	DESCRIPCION nvarchar(255) not null,
	SUBCATEGORIA_ID decimal(18, 0) not null,
	MARCA_ID decimal(18, 0) not null,
	CONSTRAINT FK_PRODUCTO_SUBCATEGORIA FOREIGN KEY (SUBCATEGORIA_ID) REFERENCES DASE_DE_BATOS.SUBCATEGORIAS(ID)
	CONSTRAINT FK_PRODUCTO_MARCA FOREIGN KEY (MARCA_ID) REFERENCES DASE_DE_BATOS.MARCAS(ID),
);

CREATE TABLE DASE_DE_BATOS.REGLAS (
	ID decimal(18, 0) PRIMARY KEY,
	DESCRIPCION nvarchar(255) not null,
	DESCUENTO decimal(18, 2) not null,
	CANTIDAD_MIN_PRODUCTOS decimal(18, 0) not null,
	CANTIDAD_PRODUCTOS_APLICADO decimal(18, 0) not null
	MAX_USOS_X_VENTA decimal(18, 0) not null
	MISMA_MARCA bit not null
	MISMO_PRODUCTO bit not null
);

CREATE TABLE DASE_DE_BATOS.PROMOCIONES (
	ID decimal(18, 0) PRIMARY KEY,
	DESCRIPCION nvarchar(255) not null,
	FECHA_INICIO datetime not null,
	FECHA_FIN datetime not null,
	REGLA_ID decimal(18, 0) not null,
	CONSTRAINT FK_PROMOCION_REGLA FOREIGN KEY (REGLA_ID) REFERENCES DASE_DE_BATOS.REGLAS(ID)
);

CREATE TABLE DASE_DE_BATOS.PRODUCTO_APLICABLE_PROMOCION (
	ID decimal(18, 0) PRIMARY KEY,
	PRODUCTO_ID decimal(18, 0) not null,
	PROMOCION_ID decimal(18, 0) not null,
	CONSTRAINT FK_PRODUCTO_APLICABLE_PROMOCION_PRODUCTO FOREIGN KEY (PRODUCTO_ID) REFERENCES DASE_DE_BATOS.PRODUCTOS(ID),
	CONSTRAINT FK_PRODUCTO_APLICABLE_PROMOCION_PROMOCION FOREIGN KEY (PROMOCION_ID) REFERENCES DASE_DE_BATOS.PROMOCIONES(ID)
);


CREATE TABLE DASE_DE_BATOS.ITEMS_VENTA (
	ID decimal(18, 0) PRIMARY KEY,
	VENTA_ID decimal(18, 0) not null,
	PRODUCTO_ID decimal(18, 0) not null,
	PRECIO decimal(18, 2) not null,
	CANTIDAD decimal(18, 2) not null,
	CONSTRAINT FK_ITEM_VENTA_PRODUCTO FOREIGN KEY (PRODUCTO_ID) REFERENCES DASE_DE_BATOS.PRODUCTOS(ID),
	CONSTRAINT FK_ITEM_VENTA_VENTA FOREIGN KEY (VENTA_ID) REFERENCES DASE_DE_BATOS.VENTAS(ID)
);

CREATE TABLE DASE_DE_BATOS.ITEM_VENTA_PROMOCION (
	ITEM_ID decimal(18, 0) not null,
	PROMOCION_ID decimal(18, 0) not null,
	PRIMARY KEY (ITEM_ID, PROMOCION_ID)
	CONSTRAINT FK_ITEM_VENTA_PROMOCION_ITEM_VENTA FOREIGN KEY (ITEM_ID) REFERENCES DASE_DE_BATOS.ITEMS_VENTA(ID),
	CONSTRAINT FK_ITEM_VENTA_PROMOCION_PROMOCION FOREIGN KEY (PROMOCION_ID) REFERENCES DASE_DE_BATOS.PRODUCTO_APLICABLE_PROMOCION(ID)
);

CREATE TABLE DASE_DE_BATOS.CLIENTES (
	ID decimal(18, 0) PRIMARY KEY,
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
	ID decimal(18, 0) PRIMARY KEY,
	ESTADO nvarchar(50) -- Finalizado, NULL
);

CREATE TABLE DASE_DE_BATOS.ENVIOS (
	ID decimal(18, 0) PRIMARY KEY,
	FECHA_PROGRAMADA datetime not null,
	FECHA_HORA_ENTREGA datetime not null,
	HORARIO_INICIO decimal(18, 0) not null,
	HORARIO_FIN decimal(18, 0) not null,
	COSTO decimal(18, 2) not null,
	ESTADO_ENVIO_ID decimal(18, 0) not null,
	VENTA_ID decimal(18, 0) not null,
	CLIENTE_ID decimal(18, 0) not null,
	CONSTRAINT FK_ENVIO_ESTADO FOREIGN KEY (ESTADO_ENVIO_ID) REFERENCES DASE_DE_BATOS.ESTADOS_ENVIO(ID)
	CONSTRAINT FK_ENVIO_VENTA FOREIGN KEY (VENTA_ID) REFERENCES DASE_DE_BATOS.VENTAS(ID),
	CONSTRAINT FK_ENVIO_CLIENTE FOREIGN KEY (CLIENTE_ID) REFERENCES DASE_DE_BATOS.CLIENTES(ID)
);

CREATE TABLE DASE_DE_BATOS.MEDIOS_DE_PAGO (
	ID decimal(18, 0) PRIMARY KEY,
	NOMBRE nvarchar(50) not null
);

CREATE TABLE DASE_DE_BATOS.PAGOS (
	ID decimal(18, 0) PRIMARY KEY,
	FECHA_HORA datetime not null,
	IMPORTE decimal(18, 2) not null,
	VENTA_ID decimal(18, 0) not null,
	MEDIO_DE_PAGO_ID decimal(18, 0) not null,
	CONSTRAINT FK_PAGO_VENTA FOREIGN KEY (VENTA_ID) REFERENCES DASE_DE_BATOS.VENTAS(ID),
	CONSTRAINT FK_PAGO_MEDIO_DE_PAGO FOREIGN KEY (MEDIO_DE_PAGO_ID) REFERENCES DASE_DE_BATOS.MEDIOS_DE_PAGO(ID)
);

CREATE TABLE DASE_DE_BATOS.DETALLES_PAGO (
	PAGO_ID decimal(18, 0) not null,
	CLIENTE_ID decimal(18, 0) not null,
	NRO_TARJETA decimal(18, 0) not null,
	FECHA_VENCIMIENTO_TARJETA date not null,
	CUOTAS decimal(18, 0) not null,
	PRIMARY KEY (PAGO_ID, CLIENTE_ID)
	CONSTRAINT FK_DETALLE_PAGO_PAGO FOREIGN KEY (PAGO_ID) REFERENCES DASE_DE_BATOS.PAGOS(ID)
);

CREATE TABLE DASE_DE_BATOS.DESCUENTOS_MEDIO_DE_PAGO (
	ID decimal(18, 0) PRIMARY KEY,
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
	PRIMARY KEY (DESCUENTO_ID, PAGO_ID)
	CONSTRAINT FK_PAGO_DESCUENTO_PAGO FOREIGN KEY (PAGO_ID) REFERENCES DASE_DE_BATOS.PAGOS(ID),
	CONSTRAINT FK_PAGO_DESCUENTO_DESCUENTO_MEDIO_DE_PAGO FOREIGN KEY (DESCUENTO_ID) REFERENCES DASE_DE_BATOS.DESCUENTOS_MEDIO_DE_PAGO(ID)
);

