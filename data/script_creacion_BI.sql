USE GD1C2023;
GO

-------- Setup --------

SET Language 'Spanish';
GO

---- Drop constraints ----
DECLARE @drop_constraints_bi NVARCHAR(max) = ''
SELECT @drop_constraints_bi += 'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(f.parent_object_id)) + '.'
												+  QUOTENAME(OBJECT_NAME(f.parent_object_id)) + ' ' + 'DROP CONSTRAINT ' + QUOTENAME(f.name) + '; '
FROM sys.foreign_keys f
INNER JOIN sys.tables t ON f.parent_object_id = t.object_id
WHERE t.name LIKE 'BI_%'

EXEC sp_executesql @drop_constraints_bi;
GO
----

---- Drop tablas ----
DECLARE @drop_tablas_bi NVARCHAR(max) = ''
SELECT @drop_tablas_bi += 'DROP TABLE DASE_DE_BATOS.' + QUOTENAME(TABLE_NAME)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DASE_DE_BATOS' and TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME LIKE 'BI_%'

EXEC sp_executesql @drop_tablas_bi;
GO
----

---- Drop functions ----
DECLARE @drop_functions_bi NVARCHAR(max) = ''
SELECT @drop_functions_bi += 'DROP FUNCTION DASE_DE_BATOS.' + QUOTENAME(NAME) + '; '
FROM sys.objects
WHERE schema_id = SCHEMA_ID('DASE_DE_BATOS') AND type IN ('FN', 'IF', 'TF', 'FS', 'FT')
AND NAME LIKE 'BI_%'

EXEC sp_executesql @drop_functions_bi;
GO
----

---- Drop procedures ----
DECLARE @drop_procedures_bi NVARCHAR(max) = ''
SELECT @drop_procedures_bi += 'DROP PROCEDURE DASE_DE_BATOS.' + QUOTENAME(NAME) + '; '
FROM sys.procedures
WHERE schema_id = SCHEMA_ID('DASE_DE_BATOS') AND NAME LIKE 'BI_%'

EXEC sp_executesql @drop_procedures_bi;
GO
----

---- Drop views ----
DECLARE @drop_views_bi NVARCHAR(max) = ''
SELECT @drop_views_bi += 'DROP VIEW DASE_DE_BATOS.' + QUOTENAME(NAME) + '; '
FROM sys.views
WHERE schema_id = SCHEMA_ID('DASE_DE_BATOS') AND NAME LIKE 'BI_%'

EXEC sp_executesql @drop_views_bi;
GO
----
--------

-------- Setup dimensiones --------

---- Create tablas dimensiones ----
CREATE TABLE DASE_DE_BATOS.BI_dimension_tiempo(
	ID decimal(18,0) IDENTITY PRIMARY KEY,
	MES int not null,
	-- CUATRIMESTRE
	ANIO int not null,
)

CREATE TABLE DASE_DE_BATOS.BI_dimension_provincia_localidad(
	ID decimal(18,0) IDENTITY PRIMARY KEY,
	PROVINCIA nvarchar(255) not null,
	LOCALIDAD nvarchar(255) not null
)

CREATE TABLE DASE_DE_BATOS.BI_migrar_dimension_sucursal(
	ID decimal(18,0) IDENTITY PRIMARY KEY,
	SUCURSAL nvarchar(255) not null
)

CREATE TABLE DASE_DE_BATOS.BI_dimension_rango_etario(
	ID decimal(18,0) IDENTITY PRIMARY KEY,
	RANGO nvarchar(10) not null
)

CREATE TABLE DASE_DE_BATOS.BI_dimension_turno(
	ID decimal(18,0) IDENTITY PRIMARY KEY,
	TURNO nvarchar(15) not null
)

CREATE TABLE DASE_DE_BATOS.BI_dimension_medio_pago(
	ID decimal(18,0) IDENTITY PRIMARY KEY,
	MEDIO_PAGO nvarchar(50) not null
)

CREATE TABLE DASE_DE_BATOS.BI_dimension_categoria_subcategoria(
	ID decimal(18,0) IDENTITY PRIMARY KEY,
	CATEGORIA nvarchar(255) not null,
	SUBCATEGORIA nvarchar(255) not null
)
GO
----
--------

-------- Migración dimensiones --------

---- Create procedures dimensiones ----

CREATE PROCEDURE DASE_DE_BATOS.BI_migrar_dimension_tiempo
	AS
		BEGIN
			INSERT INTO DASE_DE_BATOS.BI_dimension_tiempo(MES, ANIO)
				SELECT
					MONTH(em.FECHA),
					YEAR(em.FECHA)
				FROM DASE_DE_BATOS.ENVIOS_MENSAJERIA em
				WHERE em.FECHA IS NOT NULL

				UNION

				SELECT
					MONTH(em.FECHA_ENTREGA),
					YEAR(em.FECHA_ENTREGA)
				FROM DASE_DE_BATOS.ENVIOS_MENSAJERIA em
				WHERE em.FECHA_ENTREGA IS NOT NULL

				UNION

				SELECT
					MONTH(p.FECHA),
					YEAR(p.FECHA)
				FROM DASE_DE_BATOS.PEDIDOS p
				WHERE p.FECHA IS NOT NULL

				UNION

				SELECT
					MONTH(p.FECHA_ENTREGA),
					YEAR(p.FECHA_ENTREGA)
				FROM DASE_DE_BATOS.PEDIDOS p
				WHERE p.FECHA_ENTREGA IS NOT NULL

				UNION

				SELECT
					MONTH(r.FECHA),
					YEAR(r.FECHA)
				FROM DASE_DE_BATOS.RECLAMOS r
				WHERE r.FECHA IS NOT NULL

				UNION

				SELECT
					MONTH(r.FECHA_SOLUCION),
					YEAR(r.FECHA_SOLUCION)
				FROM DASE_DE_BATOS.RECLAMOS r
				WHERE r.FECHA_SOLUCION IS NOT NULL

				UNION

				SELECT
					MONTH(c.FECHA_ALTA),
					YEAR(c.FECHA_ALTA)
				FROM DASE_DE_BATOS.CUPONES c
				WHERE c.FECHA_ALTA IS NOT NULL

				UNION

				SELECT
					MONTH(c.FECHA_VENCIMIENTO),
					YEAR(c.FECHA_VENCIMIENTO)
				FROM DASE_DE_BATOS.CUPONES c
				WHERE c.FECHA_VENCIMIENTO IS NOT NULL
		END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_migrar_dimension_provincia_localidad
	AS
		BEGIN
			INSERT INTO DASE_DE_BATOS.BI_dimension_provincia_localidad(PROVINCIA, LOCALIDAD)
				SELECT
				p.NOMBRE,
				l.NOMBRE
				FROM DASE_DE_BATOS.LOCALIDADES l
					JOIN DASE_DE_BATOS.PROVINCIAS p ON l.PROVINCIA_ID = p.ID
		END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_migrar_dimension_sucursal
	AS
		BEGIN
		INSERT INTO DASE_DE_BATOS.BI_dimension_sucursal(SUCURSAL)
			SELECT s.NOMBRE
			FROM DASE_DE_BATOS.SUCURSALES s
		END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_migrar_dimension_rango_etario
	AS
		BEGIN
			INSERT INTO DASE_DE_BATOS.BI_dimension_rango_etario(RANGO)
			VALUES ('<25'),
					('25 - 35'),
					('35 - 50'),
					('>50');
		END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_migrar_dimension_turno
	AS
		BEGIN
		INSERT INTO DASE_DE_BATOS.BI_dimension_turno(RANGO)
			VALUES ('08:00 - 12:00'),
					('12:00 - 16:00'),
					('16:00 - 20:00');
		END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_migrar_dimension_medio_pago
	AS
		BEGIN
		INSERT INTO DASE_DE_BATOS.BI_dimension_medio_pago(MEDIO_PAGO)
			SELECT
			mpt.TIPO
			FROM DASE_DE_BATOS.MEDIO_DE_PAGO_TIPOS mpt
		END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_migrar_dimension_categoria_subcategoria
	AS
		BEGIN
		INSERT INTO DASE_DE_BATOS.BI_dimension_categoria_subcategoria(CATEGORIA, SUBCATEGORIA)
			SELECT
			c.NOMBRE,
			sc.NOMBRE
			FROM DASE_DE_BATOS.CATEGORIAS c
				JOIN DASE_DE_BATOS.SUBCATEGORIAS sc ON c.ID = sc.CATEGORIA_ID
		END
GO
----

---- Execute procedures ----
EXEC DASE_DE_BATOS.BI_migrar_dimension_tiempo
EXEC DASE_DE_BATOS.BI_migrar_dimension_provincia_localidad
EXEC DASE_DE_BATOS.BI_migrar_dimension_sucursal
EXEC DASE_DE_BATOS.BI_migrar_dimension_rango_etario
EXEC DASE_DE_BATOS.BI_migrar_dimension_turno
EXEC DASE_DE_BATOS.BI_migrar_dimension_medio_pago
GO
----
--------


-------- Setup hechos --------
---- Create functions ----
CREATE FUNCTION DASE_DE_BATOS.BI_obtener_rango_etario (@fecha_de_nacimiento datetime)
		RETURNS nvarchar(10)
AS
BEGIN
		DECLARE @edad int;
		SELECT @edad = (DATEDIFF (DAYOFYEAR, @fecha_de_nacimiento, GETDATE())) / 365;
		DECLARE @rango_etario nvarchar(10);

		IF (@edad < 25)
				BEGIN
						SET @rango_etario = '<25';
				END
		ELSE IF (@edad >= 25 AND @edad < 35)
				BEGIN
						SET @rango_etario = '25 - 35';
				END
		ELSE IF (@edad >= 35 AND @edad <= 50)
				BEGIN
						SET @rango_etario = '35 - 50';
				END
		ELSE IF(@edad > 50)
				BEGIN
						SET @rango_etario = '>50';
				END
		RETURN @rango_etario
END
GO


CREATE FUNCTION DASE_DE_BATOS.BI_obtener_turno (@fecha datetime)
		RETURNS nvarchar(15)
AS
BEGIN
		DECLARE @hora int;
		SELECT @hora =  (CONVERT(int, DATEPART(HOUR, @fecha)));
		DECLARE @turno nvarchar(15);

		IF (@hora >= 8 and @hora < 12)
			BEGIN
				SET @turno = '08:00 - 12:00';
			END
		ELSE IF (@hora >= 12 AND @hora < 16)
			BEGIN
				SET @turno = '12:00 - 16:00';
			END
		ELSE IF (@hora >= 16 AND @hora < 20)
			BEGIN
				SET @turno = '16:00 - 20:00';
			END

		RETURN @turno;
END
GO
----

---- Create tablas hechos ----



GO
----
--------


-------- Migración hechos --------

---- Create procedures hechos ----


GO
----
--------


-------- Create y migración views --------

---- 1. Valor promedio de las ventas (en $) según la localidad, año y mes.
---- Se calcula en función de la sumatoria del importe de las ventas sobre el total de las mismas.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_PROMEDIO_VENTAS_X_LOCALIDAD_ANIO_MES
AS
SELECT
	SUM(hv.PRECIO) / COUNT(hv.PRECIO) AS PROMEDIO_VENTA,
	BI_dimension_provincia_localidad.PROVINCIA AS PROVINCIA,
	BI_dimension_provincia_localidad.LOCALIDAD AS LOCALIDAD,
	BI_dimension_tiempo.ANIO AS AÑO,
	BI_dimension_tiempo.MES AS MES
FROM DASE_DE_BATOS.BI_hechos_ventas hv
	JOIN DASE_DE_BATOS.BI_dimension_provincia_localidad ON hv.LOCALIDAD_ID = BI_dimension_provincia_localidad.ID
	JOIN DASE_DE_BATOS.BI_dimension_tiempo ON hv.TIEMPO_ID = BI_dimension_tiempo.ID
GROUP BY
	BI_dimension_provincia_localidad.PROVINCIA,
	BI_dimension_provincia_localidad.LOCALIDAD,
	BI_dimension_tiempo.ANIO,
	BI_dimension_tiempo.MES
GO


---- 2. Cantidad promedio de artículos que se venden en función de los tickets según el turno para cada cuatrimestre de cada año.
---- Se obtiene sumando la cantidad de artículos de todos los tickets correspondientes sobre la cantidad de tickets.
---- Si un producto tiene más de una unidad en un ticket, para el indicador se consideran todas las unidades.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_PROMEDIO_CANTIDAD_UNIDADES_X_TURNO_CUATRIMESTRE_ANIO

---- 3. Porcentaje anual de ventas registradas por rango etario del empleado según el tipo de caja para cada cuatrimestre.
---- Se calcula tomando la cantidad de ventas correspondientes sobre el total de ventas anual.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_PORCENTAJE_VENTAS_X_RANGO_ETARIO_EMPLEADO_TIPO_CAJA_CUATRIMESTRE_ANIO_%_ANIO

---- 4. Cantidad de ventas registradas por turno para cada localidad según el mes de cada año.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_CANTIDAD_VENTAS_X_TURNO_LOCALIDAD_MES_ANIO

---- 5. Porcentaje de descuento aplicados en función del total de los tickets según el mes de cada año.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_PORCENTAJE_DESCUENTO_X_TOTAL_TICKET_MES_ANIO

---- 6. Las tres categorías de productos con mayor descuento aplicado a partir de promociones para cada cuatrimestre de cada año.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_TOP_3_CATEGORIAS_%_MAYOR_DESCUENTO_PROMOCIONES_X_CUATRIMESTRE_ANIO

---- 7. Porcentaje de cumplimiento de envíos en los tiempos programados por sucursal por año/mes (desvío)

CREATE VIEW DASE_DE_BATOS.BI_VIEW_PORCENTAJE_CUMPLIMIENTO_ENVIOS_A_TIEMPO_X_SUCURSAL_ANIO_MES

---- 8. Cantidad de envíos por rango etario de clientes para cada cuatrimestre de cada año.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_CANTIDAD_ENVIOS_X_RANGO_ETARIO_CLIENTE_CUATRIMESTRE_ANIO

---- 9. Las 5 localidades (tomando la localidad del cliente) con mayor costo de envío.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_TOP_5_LOCALIDADES_CLIENTE_MAYOR_COSTO_ENVIO

---- 10. Las 3 sucursales con el mayor importe de pagos en cuotas, según el medio de pago, mes y año.
---- Se calcula sumando los importes totales de todas las ventas en cuotas.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_TOP_3_SUCURSALES_MAYOR_IMPORTE_PAGOS_CUOTAS_X_MEDIO_PAGO_MES_ANIO

---- 11. Promedio de importe de la cuota en función del rango etario del cliente.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_PROMEDIO_IMPORTE_CUOTA_X_RANGO_ETARIO_CLIENTE

---- 12. Porcentaje de descuento aplicado por cada medio de pago en función del valor de total de pagos sin el descuento, por cuatrimestre.
---- Es decir, total de descuentos sobre el total de pagos más el total de descuentos.

CREATE VIEW DASE_DE_BATOS.BI_VIEW_PORCENTAJE_DESCUENTO_X_MEDIO_PAGO_CUATRIMESTRE_%_PAGOS_SIN_DESCUENTO

--------