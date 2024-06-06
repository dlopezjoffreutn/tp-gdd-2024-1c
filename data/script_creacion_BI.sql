USE GD1C2024;
GO

-------- Setup --------
---- Drop constraints ----
DECLARE @drop_constraints_bi NVARCHAR(max) = ''
SELECT @drop_constraints_bi += 'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(f.parent_object_id)) + '.'
                               + QUOTENAME(OBJECT_NAME(f.parent_object_id)) + ' ' + 'DROP CONSTRAINT '
                               + QUOTENAME(f.name) + '; '
FROM sys.foreign_keys f
    INNER JOIN sys.tables t
        ON f.parent_object_id = t.object_id
WHERE t.name LIKE 'BI_%'

EXEC sp_executesql @drop_constraints_bi;

GO
----

---- Drop tablas ----
DECLARE @drop_tablas_bi NVARCHAR(max) = ''
SELECT @drop_tablas_bi += 'DROP TABLE DASE_DE_BATOS.' + QUOTENAME(TABLE_NAME)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DASE_DE_BATOS'
      and TABLE_TYPE = 'BASE TABLE'
      AND TABLE_NAME LIKE 'BI_%'

EXEC sp_executesql @drop_tablas_bi;

GO
----

---- Drop functions ----
DECLARE @drop_functions_bi NVARCHAR(max) = ''
SELECT @drop_functions_bi += 'DROP FUNCTION DASE_DE_BATOS.' + QUOTENAME(NAME) + '; '
FROM sys.objects
WHERE schema_id = SCHEMA_ID('DASE_DE_BATOS')
      AND type IN ( 'FN', 'IF', 'TF', 'FS', 'FT' )
      AND NAME LIKE 'BI_%'

EXEC sp_executesql @drop_functions_bi;

GO
----

---- Drop procedures ----
DECLARE @drop_procedures_bi NVARCHAR(max) = ''
SELECT @drop_procedures_bi += 'DROP PROCEDURE DASE_DE_BATOS.' + QUOTENAME(NAME) + '; '
FROM sys.procedures
WHERE schema_id = SCHEMA_ID('DASE_DE_BATOS')
      AND NAME LIKE 'BI_%'

EXEC sp_executesql @drop_procedures_bi;

GO
----

---- Drop views ----
DECLARE @drop_views_bi NVARCHAR(max) = ''
SELECT @drop_views_bi += 'DROP VIEW DASE_DE_BATOS.' + QUOTENAME(NAME) + '; '
FROM sys.views
WHERE schema_id = SCHEMA_ID('DASE_DE_BATOS')
      AND NAME LIKE 'BI_%'

EXEC sp_executesql @drop_views_bi;

GO
----
--------

-------- Setup dimensiones --------
---- Create tablas dimensiones ----
CREATE TABLE DASE_DE_BATOS.BI_DIMENSION_TIEMPO
(
    ID decimal(18, 0) IDENTITY PRIMARY KEY,
    MES int not null,
    CUATRIMESTRE int not null,
    ANIO int not null,
)

CREATE TABLE DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD
(
    ID decimal(18, 0) IDENTITY PRIMARY KEY,
    PROVINCIA nvarchar(255) not null,
    LOCALIDAD nvarchar(255) not null
)

CREATE TABLE DASE_DE_BATOS.BI_DIMENSION_SUCURSAL
(
    ID decimal(18, 0) IDENTITY PRIMARY KEY,
    SUCURSAL nvarchar(255) not null
)

CREATE TABLE DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO
(
    ID decimal(18, 0) IDENTITY PRIMARY KEY,
    RANGO nvarchar(10) not null
)

CREATE TABLE DASE_DE_BATOS.BI_DIMENSION_TURNO
(
    ID decimal(18, 0) IDENTITY PRIMARY KEY,
    TURNO nvarchar(15) not null
)

CREATE TABLE DASE_DE_BATOS.BI_DIMENSION_MEDIO_PAGO
(
    ID decimal(18, 0) IDENTITY PRIMARY KEY,
    MEDIO_PAGO nvarchar(50) not null
)

CREATE TABLE DASE_DE_BATOS.BI_DIMENSION_CATEGORIA_SUBCATEGORIA
(
    ID decimal(18, 0) IDENTITY PRIMARY KEY,
    CATEGORIA nvarchar(255) not null,
    SUBCATEGORIA nvarchar(255) not null
)
GO

CREATE TABLE DASE_DE_BATOS.BI_DIMENSION_TIPO_CAJA
(
    ID decimal(18, 0) IDENTITY PRIMARY KEY,
    TIPO_CAJA nvarchar(50) not null
)
GO
----
--------

-------- Migración dimensiones --------
---- Create procedures dimensiones ----

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_DIMENSION_TIEMPO
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_DIMENSION_TIEMPO
    (
        MES,
        CUATRIMESTRE,
        ANIO
    )
    SELECT DISTINCT
        MONTH(v.FECHA_HORA),
        CEILING(MONTH(v.FECHA_HORA) / 4.0),
        YEAR(v.FECHA_HORA)
    FROM DASE_DE_BATOS.VENTAS v
    UNION
    SELECT DISTINCT
        MONTH(ev.FECHA_PROGRAMADA),
        CEILING(MONTH(ev.FECHA_PROGRAMADA) / 4.0),
        YEAR(ev.FECHA_PROGRAMADA)
    FROM DASE_DE_BATOS.ENVIOS ev
    UNION
    SELECT DISTINCT
        MONTH(ev2.FECHA_HORA_ENTREGA),
        CEILING(MONTH(ev2.FECHA_HORA_ENTREGA) / 4.0),
        YEAR(ev2.FECHA_HORA_ENTREGA)
    FROM DASE_DE_BATOS.ENVIOS ev2
    UNION
    SELECT DISTINCT
        MONTH(pg.FECHA_HORA),
        CEILING(MONTH(pg.FECHA_HORA) / 4.0),
        YEAR(pg.FECHA_HORA)
    FROM DASE_DE_BATOS.PAGOS pg
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_DIMENSION_PROVINCIA_LOCALIDAD
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD
    (
        PROVINCIA,
        LOCALIDAD
    )
    SELECT DISTINCT
        p.NOMBRE,
        l.NOMBRE
    FROM DASE_DE_BATOS.LOCALIDADES l
        JOIN DASE_DE_BATOS.PROVINCIAS p
            ON l.PROVINCIA_ID = p.ID
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_DIMENSION_SUCURSAL
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_DIMENSION_SUCURSAL
    (
        SUCURSAL
    )
    SELECT DISTINCT
        s.NOMBRE
    FROM DASE_DE_BATOS.SUCURSALES s
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_DIMENSION_RANGO_ETARIO
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO
    (
        RANGO
    )
    VALUES ('<25'),
    ('25 - 35'),
    ('35 - 50'),
    ('>50');
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_DIMENSION_TURNO
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_DIMENSION_TURNO
    (
        TURNO
    )
    VALUES ('08:00 - 12:00'),
    ('12:00 - 16:00'),
    ('16:00 - 20:00'),
    ('Otros');
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_DIMENSION_MEDIO_PAGO
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_DIMENSION_MEDIO_PAGO
    (
        MEDIO_PAGO
    )
    SELECT DISTINCT
        mp.NOMBRE
    FROM DASE_DE_BATOS.MEDIOS_DE_PAGO mp
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_DIMENSION_CATEGORIA_SUBCATEGORIA
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_DIMENSION_CATEGORIA_SUBCATEGORIA
    (
        CATEGORIA,
        SUBCATEGORIA
    )
    SELECT DISTINCT
        c.NOMBRE,
        sc.NOMBRE
    FROM DASE_DE_BATOS.SUBCATEGORIAS sc
        JOIN DASE_DE_BATOS.CATEGORIAS c
            ON c.ID = sc.CATEGORIA_ID
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_DIMENSION_TIPO_CAJA
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_DIMENSION_TIPO_CAJA
    (
        TIPO_CAJA
    )
    SELECT DISTINCT
        tc.TIPO
    FROM DASE_DE_BATOS.CAJA_TIPOS tc
END
GO
----

---- Execute procedures ----
EXEC DASE_DE_BATOS.BI_SP_DIMENSION_TIEMPO
GO
EXEC DASE_DE_BATOS.BI_SP_DIMENSION_PROVINCIA_LOCALIDAD
GO
EXEC DASE_DE_BATOS.BI_SP_DIMENSION_SUCURSAL
GO
EXEC DASE_DE_BATOS.BI_SP_DIMENSION_RANGO_ETARIO
GO
EXEC DASE_DE_BATOS.BI_SP_DIMENSION_TURNO
GO
EXEC DASE_DE_BATOS.BI_SP_DIMENSION_MEDIO_PAGO
GO
EXEC DASE_DE_BATOS.BI_SP_DIMENSION_CATEGORIA_SUBCATEGORIA
GO
EXEC DASE_DE_BATOS.BI_SP_DIMENSION_TIPO_CAJA
GO
----
--------

-------- Setup hechos --------
---- Create functions ----
CREATE FUNCTION DASE_DE_BATOS.BI_FN_RANGO_ETARIO (@fecha_de_nacimiento datetime)
RETURNS nvarchar(10)
AS
BEGIN
    DECLARE @edad int;

    SELECT @edad = (DATEDIFF(DAYOFYEAR, @fecha_de_nacimiento, GETDATE())) / 365;

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
    ELSE IF (@edad > 50)
    BEGIN
        SET @rango_etario = '>50';
    END
    RETURN @rango_etario
END
GO


CREATE FUNCTION DASE_DE_BATOS.BI_FN_TURNO (@fecha datetime)
RETURNS nvarchar(15)
AS
BEGIN
    DECLARE @hora int;

    SELECT @hora = (CONVERT(int, DATEPART(HOUR, @fecha)));

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
    ELSE IF (@hora < 8 OR @hora >= 20)
    BEGIN
        SET @turno = 'Otros';
    END

    RETURN @turno;
END
GO
----

---- Create tablas hechos ----
CREATE TABLE DASE_DE_BATOS.BI_HECHOS_VENTAS
(
    SUBTOTAL decimal(18, 2) not null,
    TOTAL decimal(18, 2) not null,
    TOTAL_DESCUENTOS decimal(18, 2) not null,
    TOTAL_PROMOCIONES decimal(18, 2) not null,
    UNIDADES decimal(18, 0) not null,
    TIPO_CAJA_ID decimal(18, 0) not null,
    SUCURSAL_ID decimal(18, 0) not null,
    LOCALIDAD_ID decimal(18, 0) not null,
    FECHA_VENTA_ID decimal(18, 0) not null,
    RANGO_ETARIO_EMPLEADO_ID decimal(18, 0) not null,
    TURNO_ID decimal(18, 0) not null,
    CONSTRAINT FK_BI_VENTA_TIPO_CAJA
        FOREIGN KEY (TIPO_CAJA_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_TIPO_CAJA (ID),
    CONSTRAINT FK_BI_VENTA_SUCURSAL
        FOREIGN KEY (SUCURSAL_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_SUCURSAL (ID),
    CONSTRAINT FK_BI_VENTA_LOCALIDAD
        FOREIGN KEY (LOCALIDAD_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD (ID),
    CONSTRAINT FK_BI_VENTA_TIEMPO
        FOREIGN KEY (FECHA_VENTA_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_TIEMPO (ID),
    CONSTRAINT FK_BI_VENTA_RANGO_ETARIO_EMPLEADO
        FOREIGN KEY (RANGO_ETARIO_EMPLEADO_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO (ID),
    CONSTRAINT FK_BI_VENTA_TURNO
        FOREIGN KEY (TURNO_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_TURNO (ID),
)

CREATE TABLE DASE_DE_BATOS.BI_HECHOS_ITEMS_VENTA
(
    TOTAL decimal(18, 2) not null,
    TOTAL_PROMOCIONES decimal(18, 2) not null,
    CATEGORIA_ID decimal(18, 0) not null,
    FECHA_VENTA_ID decimal(18, 0) not null,
    CONSTRAINT FK_BI_ITEM_VENTA_CATEGORIA
        FOREIGN KEY (CATEGORIA_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_CATEGORIA_SUBCATEGORIA (ID),
    CONSTRAINT FK_BI_ITEM_VENTA_TIEMPO
        FOREIGN KEY (FECHA_VENTA_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_TIEMPO (ID),
)

CREATE TABLE DASE_DE_BATOS.BI_HECHOS_ENVIOS
(
    COSTO decimal(18, 2) not null,
    TIEMPO_PROGRAMADO datetime not null,
    TIEMPO_ENTREGA datetime not null,
    SUCURSAL_ID decimal(18, 0) not null,
    LOCALIDAD_ID decimal(18, 0) not null,
    TIEMPO_ENTREGA_ID decimal(18, 0) not null,
    RANGO_ETARIO_CLIENTE_ID decimal(18, 0) not null,
    CONSTRAINT FK_BI_ENVIO_LOCALIDAD
        FOREIGN KEY (LOCALIDAD_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD (ID),
    CONSTRAINT FK_BI_ENVIO_FECHA_VENTA
        FOREIGN KEY (TIEMPO_ENTREGA_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_TIEMPO (ID),
    CONSTRAINT FK_BI_ENVIO_RANGO_ETARIO_CLIENTE
        FOREIGN KEY (RANGO_ETARIO_CLIENTE_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO (ID)
)

CREATE TABLE DASE_DE_BATOS.BI_HECHOS_PAGOS_CUOTAS
(
    IMPORTE decimal(18, 2) not null,
    TOTAL_DESCUENTOS decimal(18, 2) not null,
    CUOTAS decimal(18, 0) not null,
    MEDIO_PAGO_ID decimal(18, 0) not null,
    FECHA_VENTA_ID decimal(18, 0) not null,
    SUCURSAL_ID decimal(18, 0) not null,
    RANGO_ETARIO_CLIENTE_ID decimal(18, 0) not null,
    CONSTRAINT FK_BI_PAGO_MEDIO_PAGO
        FOREIGN KEY (MEDIO_PAGO_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_MEDIO_PAGO (ID),
    CONSTRAINT FK_BI_PAGO_TIEMPO
        FOREIGN KEY (FECHA_VENTA_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_TIEMPO (ID),
    CONSTRAINT FK_BI_PAGO_SUCURSAL
        FOREIGN KEY (SUCURSAL_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_SUCURSAL (ID),
    CONSTRAINT FK_BI_PAGO_RANGO_ETARIO_CLIENTE
        FOREIGN KEY (RANGO_ETARIO_CLIENTE_ID)
        REFERENCES DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO (ID)
)
GO
----
--------

-------- Migración hechos --------
---- Create procedures hechos ----
CREATE PROCEDURE DASE_DE_BATOS.BI_SP_HECHOS_VENTAS
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_HECHOS_VENTAS
    (
        SUBTOTAL,
        TOTAL,
        TOTAL_DESCUENTOS,
        TOTAL_PROMOCIONES,
        UNIDADES,
        TIPO_CAJA_ID,
        SUCURSAL_ID,
        LOCALIDAD_ID,
        FECHA_VENTA_ID,
        RANGO_ETARIO_EMPLEADO_ID,
        TURNO_ID
    )
    SELECT v.SUBTOTAL,
           v.TOTAL,
           v.TOTAL_DESCUENTOS,
           v.TOTAL_PROMOCIONES,
           SUM(iv.CANTIDAD),
           dtc.ID,
           ds.ID,
           dpl.ID,
           (
               SELECT TOP 1
                   dt.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
               WHERE dt.MES = MONTH(v.FECHA_HORA)
                     AND dt.CUATRIMESTRE = CEILING(MONTH(v.FECHA_HORA) / 4.0)
                     AND dt.ANIO = YEAR(v.FECHA_HORA)
           ),
           (
               SELECT TOP 1
                   dre.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO dre
               WHERE dre.RANGO = DASE_DE_BATOS.BI_FN_RANGO_ETARIO(e.FECHA_NACIMIENTO)
           ),
           (
               SELECT TOP 1
                   dtu.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_TURNO dtu
               WHERE dtu.TURNO = DASE_DE_BATOS.BI_FN_TURNO(v.FECHA_HORA)
           )
    FROM DASE_DE_BATOS.VENTAS v
        JOIN DASE_DE_BATOS.ITEMS_VENTA iv
            ON iv.VENTA_ID = v.ID
        JOIN DASE_DE_BATOS.CAJAS c
            ON c.ID = v.CAJA_ID
        JOIN DASE_DE_BATOS.CAJA_TIPOS ct
            ON ct.ID = c.TIPO_ID
        JOIN DASE_DE_BATOS.BI_DIMENSION_TIPO_CAJA dtc
            ON dtc.TIPO_CAJA = ct.TIPO
        JOIN DASE_DE_BATOS.SUCURSALES s
            ON s.ID = c.SUCURSAL_ID
        JOIN DASE_DE_BATOS.BI_DIMENSION_SUCURSAL ds
            ON ds.SUCURSAL = s.NOMBRE
        JOIN DASE_DE_BATOS.LOCALIDADES l
            ON l.ID = s.LOCALIDAD_ID
        JOIN DASE_DE_BATOS.PROVINCIAS p
            ON p.ID = l.PROVINCIA_ID
        JOIN DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD dpl
            ON dpl.PROVINCIA = p.NOMBRE
               AND dpl.LOCALIDAD = l.NOMBRE
        JOIN DASE_DE_BATOS.EMPLEADOS e
            ON e.ID = v.EMPLEADO_ID
    GROUP BY v.SUBTOTAL,
             v.TOTAL,
             v.TOTAL_DESCUENTOS,
             v.TOTAL_PROMOCIONES,
             dtc.ID,
             ds.ID,
             dpl.ID,
             v.FECHA_HORA,
             e.FECHA_NACIMIENTO
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_HECHOS_ITEMS_VENTA
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_HECHOS_ITEMS_VENTA
    (
        TOTAL,
        TOTAL_PROMOCIONES,
        CATEGORIA_ID,
        FECHA_VENTA_ID
    )
    SELECT iv.TOTAL,
           iv.TOTAL_PROMOCIONES,
           dcs.ID,
           (
               SELECT TOP 1
                   dt.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
               WHERE dt.MES = MONTH(v.FECHA_HORA)
                     AND dt.CUATRIMESTRE = CEILING(MONTH(v.FECHA_HORA) / 4.0)
                     AND dt.ANIO = YEAR(v.FECHA_HORA)
           )
    FROM DASE_DE_BATOS.ITEMS_VENTA iv
        JOIN DASE_DE_BATOS.VENTAS v
            ON v.ID = iv.VENTA_ID
        JOIN DASE_DE_BATOS.ITEM_VENTA_PROMOCION ivp
            ON ivp.ITEM_ID = iv.ID
        JOIN DASE_DE_BATOS.PRODUCTO_APLICABLE_PROMOCION pap
            ON pap.ID = ivp.PROMOCION_ID
        JOIN DASE_DE_BATOS.PROMOCIONES pr
            ON pr.CODIGO = pap.CODIGO_PROMOCION
        JOIN DASE_DE_BATOS.REGLAS r
            ON r.ID = pr.REGLA_ID
        JOIN DASE_DE_BATOS.PRODUCTOS p
            ON p.ID = iv.PRODUCTO_ID
        JOIN DASE_DE_BATOS.SUBCATEGORIAS sc
            ON sc.ID = p.SUBCATEGORIA_ID
        JOIN DASE_DE_BATOS.CATEGORIAS c
            ON c.ID = sc.CATEGORIA_ID
        JOIN DASE_DE_BATOS.BI_DIMENSION_CATEGORIA_SUBCATEGORIA dcs
            ON dcs.CATEGORIA = c.NOMBRE
               AND dcs.SUBCATEGORIA = sc.NOMBRE
    GROUP BY iv.TOTAL,
             iv.TOTAL_PROMOCIONES,
             dcs.ID,
             v.FECHA_HORA
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_HECHOS_ENVIOS
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_HECHOS_ENVIOS
    (
        COSTO,
        TIEMPO_PROGRAMADO,
        TIEMPO_ENTREGA,
        SUCURSAL_ID,
        LOCALIDAD_ID,
        TIEMPO_ENTREGA_ID,
        RANGO_ETARIO_CLIENTE_ID
    )
    SELECT ev.COSTO,
           ev.FECHA_PROGRAMADA,
           ev.FECHA_HORA_ENTREGA,
           (
               SELECT TOP 1
                   ds.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_SUCURSAL ds
               WHERE ds.SUCURSAL = s.NOMBRE
           ),
           (
               SELECT TOP 1
                   dpl.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD dpl
               WHERE dpl.PROVINCIA = p.NOMBRE
                     AND dpl.LOCALIDAD = l.NOMBRE
           ),
           (
               SELECT TOP 1
                   dt.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
               WHERE dt.MES = MONTH(ev.FECHA_HORA_ENTREGA)
                     AND dt.CUATRIMESTRE = CEILING(MONTH(ev.FECHA_HORA_ENTREGA) / 4.0)
                     AND dt.ANIO = YEAR(ev.FECHA_HORA_ENTREGA)
           ),
           (
               SELECT TOP 1
                   dre.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO dre
               WHERE dre.RANGO = DASE_DE_BATOS.BI_FN_RANGO_ETARIO(c.FECHA_NACIMIENTO)
           )
    FROM DASE_DE_BATOS.ENVIOS ev
        JOIN DASE_DE_BATOS.VENTAS v
            ON v.ID = ev.VENTA_ID
        JOIN DASE_DE_BATOS.CAJAS cj
            ON cj.ID = v.CAJA_ID
        JOIN DASE_DE_BATOS.SUCURSALES s
            ON s.ID = cj.SUCURSAL_ID
        JOIN DASE_DE_BATOS.CLIENTES c
            ON c.ID = ev.CLIENTE_ID
        JOIN DASE_DE_BATOS.LOCALIDADES l
            ON l.ID = c.LOCALIDAD_ID
        JOIN DASE_DE_BATOS.PROVINCIAS p
            ON p.ID = l.PROVINCIA_ID
END
GO

CREATE PROCEDURE DASE_DE_BATOS.BI_SP_HECHOS_PAGOS_CUOTAS
AS
BEGIN
    INSERT INTO DASE_DE_BATOS.BI_HECHOS_PAGOS_CUOTAS
    (
        IMPORTE,
        TOTAL_DESCUENTOS,
        CUOTAS,
        MEDIO_PAGO_ID,
        FECHA_VENTA_ID,
        SUCURSAL_ID,
        RANGO_ETARIO_CLIENTE_ID
    )
    SELECT SUM(p.IMPORTE),
           SUM(p.TOTAL_DESCUENTOS),
           SUM(dpt.CUOTAS),
           (
               SELECT TOP 1
                   dmp.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_MEDIO_PAGO dmp
               WHERE dmp.MEDIO_PAGO = mp.NOMBRE
           ),
           (
               SELECT TOP 1
                   dt.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
               WHERE dt.MES = MONTH(p.FECHA_HORA)
                     AND dt.CUATRIMESTRE = CEILING(MONTH(p.FECHA_HORA) / 4.0)
                     AND dt.ANIO = YEAR(p.FECHA_HORA)
           ),
           (
               SELECT TOP 1
                   ds.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_SUCURSAL ds
               WHERE ds.SUCURSAL = s.NOMBRE
           ),
           (
               SELECT TOP 1
                   dre.ID
               FROM DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO dre
               WHERE dre.RANGO = DASE_DE_BATOS.BI_FN_RANGO_ETARIO(c.FECHA_NACIMIENTO)
           )
    FROM DASE_DE_BATOS.PAGOS p
        JOIN DASE_DE_BATOS.VENTAS v
            ON v.ID = p.VENTA_ID
        JOIN DASE_DE_BATOS.DETALLE_PAGO_TARJETA dpt
            ON dpt.PAGO_ID = p.ID
        JOIN DASE_DE_BATOS.MEDIOS_DE_PAGO mp
            ON mp.ID = p.MEDIO_DE_PAGO_ID
        JOIN DASE_DE_BATOS.DESCUENTOS_MEDIO_DE_PAGO dmp
            ON dmp.MEDIO_DE_PAGO_ID = mp.ID
        JOIN DASE_DE_BATOS.CAJAS ca
            ON ca.ID = v.CAJA_ID
        JOIN DASE_DE_BATOS.SUCURSALES s
            ON s.ID = ca.SUCURSAL_ID
        JOIN DASE_DE_BATOS.ENVIOS e
            ON e.VENTA_ID = v.ID
        JOIN DASE_DE_BATOS.CLIENTES c
            ON c.ID = e.CLIENTE_ID
    GROUP BY v.ID,
             mp.NOMBRE,
             p.FECHA_HORA,
             s.NOMBRE,
             c.FECHA_NACIMIENTO
END
GO
----

---- Execute procedures ----
EXEC DASE_DE_BATOS.BI_SP_HECHOS_VENTAS
GO
EXEC DASE_DE_BATOS.BI_SP_HECHOS_ITEMS_VENTA
GO
EXEC DASE_DE_BATOS.BI_SP_HECHOS_ENVIOS
GO
EXEC DASE_DE_BATOS.BI_SP_HECHOS_PAGOS_CUOTAS
GO
----
--------

-------- Create y migración views --------
---- 1. Valor promedio de las ventas (en $) según la localidad, año y mes.
---- Se calcula en función de la sumatoria del importe de las ventas sobre el total de las mismas.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_PROMEDIO_VENTAS_X_LOCALIDAD_ANIO_MES
AS
SELECT ROUND(SUM(hv.TOTAL) / COUNT(hv.TOTAL), 2) AS PROMEDIO_VENTAS,
       dpl.LOCALIDAD AS LOCALIDAD,
       dpl.PROVINCIA AS PROVINCIA,
       dt.MES AS MES,
       dt.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_VENTAS hv
    JOIN DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD dpl
        ON dpl.ID = hv.LOCALIDAD_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = hv.FECHA_VENTA_ID
GROUP BY dpl.LOCALIDAD,
         dpl.PROVINCIA,
         dt.MES,
         dt.ANIO
GO

---- 2. Cantidad promedio de artículos que se venden en función de los tickets según el turno para cada cuatrimestre de cada año.
---- Se obtiene sumando la cantidad de artículos de todos los tickets correspondientes sobre la cantidad de tickets.
---- Si un producto tiene más de una unidad en un ticket, para el indicador se consideran todas las unidades.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_PROMEDIO_CANTIDAD_UNIDADES_X_TURNO_CUATRIMESTRE_ANIO
AS
SELECT ROUND(SUM(hv.UNIDADES) / COUNT(*), 2) AS PROMEDIO_CANTIDAD_UNIDADES,
       dtu.TURNO AS TURNO,
       dt.CUATRIMESTRE AS CUATRIMESTRE,
       dt.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_VENTAS hv
    JOIN DASE_DE_BATOS.BI_DIMENSION_TURNO dtu
        ON dtu.ID = hv.TURNO_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = hv.FECHA_VENTA_ID
GROUP BY dtu.TURNO,
         dt.CUATRIMESTRE,
         dt.ANIO
GO

---- 3. Porcentaje anual de ventas registradas por rango etario del empleado según el tipo de caja para cada cuatrimestre.
---- Se calcula tomando la cantidad de ventas correspondientes sobre el total de ventas anual.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_PORCENTAJE_VENTAS_X_RANGO_ETARIO_EMPLEADO_TIPO_CAJA_CUATRIMESTRE_SOBRE_ANIO
AS
SELECT '~'
       + CAST((COUNT(*) * 100 / SUM(COUNT(*)) OVER (PARTITION BY dt.ANIO, dre.RANGO, dtc.TIPO_CAJA)) AS NVARCHAR(5))
       + '%' as PORCENTAJE_VENTAS,
       dre.RANGO AS RANGO_ETARIO_EMPLEADO,
       dtc.TIPO_CAJA AS TIPO_CAJA,
       dt.CUATRIMESTRE AS CUATRIMESTRE,
       dt.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_VENTAS hv
    JOIN DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO dre
        ON dre.ID = hv.RANGO_ETARIO_EMPLEADO_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIPO_CAJA dtc
        ON dtc.ID = hv.TIPO_CAJA_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = hv.FECHA_VENTA_ID
GROUP BY dt.CUATRIMESTRE,
         dt.ANIO,
         dre.RANGO,
         dtc.TIPO_CAJA
GO

---- 4. Cantidad de ventas registradas por turno para cada localidad según el mes de cada año.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_CANTIDAD_VENTAS_X_TURNO_LOCALIDAD_MES_ANIO
AS
SELECT COUNT(*) AS CANTIDAD_VENTAS,
       dtu.TURNO AS TURNO,
       dpl.LOCALIDAD AS LOCALIDAD,
       dt.MES AS MES,
       dt.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_VENTAS hv
    JOIN DASE_DE_BATOS.BI_DIMENSION_TURNO dtu
        ON dtu.ID = hv.TURNO_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD dpl
        ON dpl.ID = hv.LOCALIDAD_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = hv.FECHA_VENTA_ID
GROUP BY dtu.TURNO,
         dpl.LOCALIDAD,
         dt.MES,
         dt.ANIO
GO

---- 5. Porcentaje de descuento aplicados en función del total de los tickets según el mes de cada año.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_PORCENTAJE_DESCUENTO_X_TOTAL_TICKET_MES_ANIO
AS
SELECT '~' + CAST(CAST(ROUND(SUM(hv.TOTAL_DESCUENTOS) * 100 / SUM(hv.TOTAL), 0) AS INT) AS NVARCHAR(5)) + '%' as PORCENTAJE_DESCUENTO,
       dt.MES AS MES,
       dt.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_VENTAS hv
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = hv.FECHA_VENTA_ID
GROUP BY dt.MES,
         dt.ANIO
GO

---- 6. Las tres categorías de productos con mayor descuento aplicado a partir de promociones para cada cuatrimestre de cada año.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_TOP_3_CATEGORIAS_MAYOR_DESCUENTO_PROMOCIONES_X_CUATRIMESTRE_ANIO
AS
SELECT TOP 3 WITH TIES
    SUM(hiv.TOTAL_PROMOCIONES) AS DESCUENTO_APLICADO,
    dcs.CATEGORIA AS CATEGORIA,
    dt.CUATRIMESTRE AS CUATRIMESTRE,
    dt.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_ITEMS_VENTA hiv
    JOIN DASE_DE_BATOS.BI_DIMENSION_CATEGORIA_SUBCATEGORIA dcs
        ON dcs.ID = hiv.CATEGORIA_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = hiv.FECHA_VENTA_ID
GROUP BY dcs.CATEGORIA,
         dt.CUATRIMESTRE,
         dt.ANIO
ORDER BY DESCUENTO_APLICADO DESC
GO

---- 7. Porcentaje de cumplimiento de envíos en los tiempos programados por sucursal por año/mes (desvío)
CREATE VIEW DASE_DE_BATOS.BI_VIEW_PORCENTAJE_CUMPLIMIENTO_ENVIOS_A_TIEMPO_X_SUCURSAL_ANIO_MES
AS
SELECT CAST((
			COUNT(
				CASE
					WHEN CAST(ev.TIEMPO_ENTREGA AS DATE) <= CAST(ev.TIEMPO_PROGRAMADO AS DATE)
					THEN 1
				END
			) * 100 / COUNT(*)
		) AS NVARCHAR(5)) + '%' as PORCENTAJE_CUMPLIMIENTO,
       ds.SUCURSAL AS SUCURSAL,
       tv.MES AS MES,
       tv.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_ENVIOS ev
    JOIN DASE_DE_BATOS.BI_DIMENSION_SUCURSAL ds
        ON ds.ID = ev.SUCURSAL_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO tv
        ON tv.ID = ev.TIEMPO_ENTREGA_ID
GROUP BY ds.SUCURSAL,
         tv.MES,
         tv.ANIO
GO

---- 8. Cantidad de envíos por rango etario de clientes para cada cuatrimestre de cada año.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_CANTIDAD_ENVIOS_X_RANGO_ETARIO_CLIENTE_CUATRIMESTRE_ANIO
AS
SELECT COUNT(*) AS CANTIDAD_ENVIOS,
       dre.RANGO AS RANGO_ETARIO_CLIENTE,
       dt.CUATRIMESTRE AS CUATRIMESTRE,
       dt.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_ENVIOS ev
    JOIN DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO dre
        ON dre.ID = ev.RANGO_ETARIO_CLIENTE_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = ev.TIEMPO_ENTREGA_ID
GROUP BY dre.RANGO,
         dt.CUATRIMESTRE,
         dt.ANIO
GO

---- 9. Las 5 localidades (tomando la localidad del cliente) con mayor costo de envío.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_TOP_5_LOCALIDADES_CLIENTE_MAYOR_COSTO_ENVIO
AS
SELECT TOP 5 WITH TIES
    SUM(ev.COSTO) AS COSTO_ENVIO,
    dpl.LOCALIDAD AS LOCALIDAD,
    dpl.PROVINCIA AS PROVINCIA
FROM DASE_DE_BATOS.BI_HECHOS_ENVIOS ev
    JOIN DASE_DE_BATOS.BI_DIMENSION_PROVINCIA_LOCALIDAD dpl
        ON dpl.ID = ev.LOCALIDAD_ID
GROUP BY dpl.LOCALIDAD,
         dpl.PROVINCIA
ORDER BY COSTO_ENVIO DESC
GO

---- 10. Las 3 sucursales con el mayor importe de pagos en cuotas, según el medio de pago, mes y año.
---- Se calcula sumando los importes totales de todas las ventas en cuotas.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_TOP_3_SUCURSALES_MAYOR_IMPORTE_PAGOS_CUOTAS_X_MEDIO_PAGO_MES_ANIO
AS
SELECT TOP 3 WITH TIES
    SUM(hp.IMPORTE) AS IMPORTE_PAGOS_CUOTAS,
    ds.SUCURSAL AS SUCURSAL,
    dmp.MEDIO_PAGO AS MEDIO_PAGO,
    dt.MES AS MES,
    dt.ANIO AS AÑO
FROM DASE_DE_BATOS.BI_HECHOS_PAGOS_CUOTAS hp
    JOIN DASE_DE_BATOS.BI_DIMENSION_MEDIO_PAGO dmp
        ON dmp.ID = hp.MEDIO_PAGO_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_SUCURSAL ds
        ON ds.ID = hp.SUCURSAL_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = hp.FECHA_VENTA_ID
GROUP BY ds.SUCURSAL,
         dmp.MEDIO_PAGO,
         dt.MES,
         dt.ANIO
ORDER BY IMPORTE_PAGOS_CUOTAS DESC
GO

---- 11. Promedio de importe de la cuota en función del rango etario del cliente.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_PROMEDIO_IMPORTE_CUOTA_X_RANGO_ETARIO_CLIENTE
AS
SELECT ROUND(SUM(hp.IMPORTE) / SUM(hp.CUOTAS), 2) AS PROMEDIO_IMPORTE_CUOTA,
       dre.RANGO AS RANGO_ETARIO_CLIENTE
FROM DASE_DE_BATOS.BI_HECHOS_PAGOS_CUOTAS hp
    JOIN DASE_DE_BATOS.BI_DIMENSION_RANGO_ETARIO dre
        ON dre.ID = hp.RANGO_ETARIO_CLIENTE_ID
GROUP BY dre.RANGO
GO

---- 12. Porcentaje de descuento aplicado por cada medio de pago en función del valor de total de pagos sin el descuento, por cuatrimestre.
---- Es decir, total de descuentos sobre el total de pagos más el total de descuentos.
CREATE VIEW DASE_DE_BATOS.BI_VIEW_PORCENTAJE_DESCUENTO_X_MEDIO_PAGO_CUATRIMESTRE_SOBRE_PAGOS_SIN_DESCUENTO
AS
SELECT '~'
       + CAST(CAST(ROUND(SUM(hp.TOTAL_DESCUENTOS) * 100 / (SUM(hp.IMPORTE) + SUM(hp.TOTAL_DESCUENTOS)), 0) AS INT) AS NVARCHAR(5))
       + '%' as PORCENTAJE_DESCUENTO,
       dmp.MEDIO_PAGO AS MEDIO_PAGO,
       dt.CUATRIMESTRE AS CUATRIMESTRE
FROM DASE_DE_BATOS.BI_HECHOS_PAGOS_CUOTAS hp
    JOIN DASE_DE_BATOS.BI_DIMENSION_MEDIO_PAGO dmp
        ON dmp.ID = hp.MEDIO_PAGO_ID
    JOIN DASE_DE_BATOS.BI_DIMENSION_TIEMPO dt
        ON dt.ID = hp.FECHA_VENTA_ID
GROUP BY dmp.MEDIO_PAGO,
         dt.CUATRIMESTRE
GO
--------