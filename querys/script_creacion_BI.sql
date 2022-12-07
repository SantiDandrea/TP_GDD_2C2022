USE [GD2C2022]
GO

----CREACION DE TABLAS---- 

--DIMENSIONES

CREATE TABLE NOT_FOUND.BI_DIMENSION_TIEMPO(
	TIEMPO_ID INT IDENTITY PRIMARY KEY,
	A�O INT,
	MES INT
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_PROVINCIA(
	PROVINCIA_ID INT PRIMARY KEY,
	PROVINCIA NVARCHAR(255)
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_TIPO_DE_ENVIO(
	TIPO_ENVIO_ID INT PRIMARY KEY,
	TIPO_ENVIO NVARCHAR(255)
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_MEDIO_DE_PAGO(
	MEDIO_PAGO_ID INT PRIMARY KEY,
	MEDIO_PAGO NVARCHAR(255)
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_CANAL_DE_VENTA(
	CANAL_ID INT PRIMARY KEY,
	CANAL NVARCHAR(255),
	COSTO_CANAL DECIMAL(18,2)
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_TIPO_DE_DESCUENTO(
	TIPO_DESCUENTO_ID INT PRIMARY KEY,
	TIPO_DESCUENTO NVARCHAR(255)
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_RANGO_ETARIO(
	RANGO_ETARIO_ID INT IDENTITY PRIMARY KEY,
	RANGO NVARCHAR(5)
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_CATEGORIA(
	CATEGORIA_ID INT PRIMARY KEY,
	CATEGORIA NVARCHAR(255)
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_PRODUCTO(
	PRODUCTO_ID NVARCHAR(50) PRIMARY KEY,
	NOMBRE_PRODUCTO NVARCHAR(50),
	DESCRIPCION_PRODUCTO NVARCHAR(50)
)
GO

CREATE TABLE NOT_FOUND.BI_DIMENSION_PROVEEDOR(
	PROVEEDOR_ID NVARCHAR(50) PRIMARY KEY,
	RAZON_SOCIAL NVARCHAR(50),
	DOMICILIO NVARCHAR(50),
	MAIL NVARCHAR(50)
)
GO

---HECHOS
CREATE TABLE NOT_FOUND.BI_HECHOS_VENTAS(
	CANAL_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_CANAL_DE_VENTA,
	MEDIO_PAGO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_MEDIO_DE_PAGO,
	TIPO_ENVIO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_TIPO_DE_ENVIO,
	PROVINCIA_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_PROVINCIA, 
	TIEMPO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_TIEMPO,
	TOTAL_VENTA DECIMAL(18,2),
	PRECIO_PROM_MEDIO_ENVIO DECIMAL(18,2),
	COSTO_MEDIO_PAGO DECIMAL(18,2),
	CANTIDAD_DE_ENVIOS int
	PRIMARY KEY (CANAL_ID,MEDIO_PAGO_ID,TIPO_ENVIO_ID,PROVINCIA_ID,TIEMPO_ID)
)
GO


CREATE TABLE NOT_FOUND.BI_HECHOS_DESCUENTOS(
	CANAL_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_CANAL_DE_VENTA,
	TIPO_DESCUENTO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_TIPO_DE_DESCUENTO,
	MEDIO_PAGO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_MEDIO_DE_PAGO,
	TIEMPO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_TIEMPO,
	IMPORTE DECIMAL(18,2)
	PRIMARY KEY (CANAL_ID, TIPO_DESCUENTO_ID, MEDIO_PAGO_ID, TIEMPO_ID)
)
GO

CREATE TABLE NOT_FOUND.BI_HECHOS_COMPRAS(
	PROVEEDOR_ID NVARCHAR(50) REFERENCES NOT_FOUND.BI_DIMENSION_PROVEEDOR,
	PRODUCTO_ID NVARCHAR(50) REFERENCES NOT_FOUND.BI_DIMENSION_PRODUCTO,
	TIEMPO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_TIEMPO,
	REPOSICION DECIMAL(18,0),
	PRECIO_MAXIMO DECIMAL(18,2), 
	PRECIO_MINIMO DECIMAL(18,2),
	TOTAL_COMPRA DECIMAL(18,2),
	PRIMARY KEY (PROVEEDOR_ID,PRODUCTO_ID,TIEMPO_ID)
)
GO

CREATE TABLE NOT_FOUND.BI_HECHOS_PRODUCTOS_VENDIDOS(
	RANGO_ETARIO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_RANGO_ETARIO,
	PRODUCTO_ID NVARCHAR(50) REFERENCES NOT_FOUND.BI_DIMENSION_PRODUCTO,
	CATEGORIA_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_CATEGORIA,
	TIEMPO_ID INT REFERENCES NOT_FOUND.BI_DIMENSION_TIEMPO,
	UNIDADES DECIMAL(18,0),
	INGRESOS DECIMAL(18,2)
	PRIMARY KEY (RANGO_ETARIO_ID, PRODUCTO_ID, CATEGORIA_ID,TIEMPO_ID) 
)
GO
------------------------

--PROCEDURES MIGRACION TRANSACCIONAL A DIMENSIONAL------

CREATE FUNCTION NOT_FOUND.rango_etario(@fecha_nac date)
RETURNS nvarchar(5)
BEGIN
	DECLARE @edad INT
	IF(MONTH(@fecha_nac) <= MONTH(GETDATE()) AND DAY(@fecha_nac) <= DAY(GETDATE()))
	BEGIN
		SET @edad = YEAR(GETDATE()) - YEAR(@fecha_nac) 
	END
	ELSE SET @edad = YEAR(GETDATE()) - YEAR(@fecha_nac) - 1 

	RETURN CASE WHEN @edad < 25 THEN '<25'
			    WHEN @edad between 25 and 35 THEN '25-35'
			    WHEN @edad > 35 AND @edad <= 55 THEN '35-55'
			    ELSE '>55' END
END
GO


CREATE PROCEDURE NOT_FOUND.BI_migrar_tiempos
 AS
  BEGIN
    INSERT INTO NOT_FOUND.BI_DIMENSION_TIEMPO(A�O,MES)
	SELECT DISTINCT YEAR(VENTA_FECHA), MONTH(VENTA_FECHA) 
	FROM NOT_FOUND.VENTA 
	ORDER BY YEAR(VENTA_FECHA), MONTH(VENTA_FECHA)
  END
GO


CREATE PROCEDURE NOT_FOUND.BI_migrar_categorias
 AS
  BEGIN
    INSERT INTO NOT_FOUND.BI_DIMENSION_CATEGORIA(CATEGORIA_ID,CATEGORIA)
	SELECT CATEGORIA_CODIGO,CATEGORIA_DESCRIPCION 
	FROM NOT_FOUND.CATEGORIA
  END
GO

CREATE PROCEDURE NOT_FOUND.BI_migrar_rangos_etarios
 AS
  BEGIN
    INSERT INTO NOT_FOUND.BI_DIMENSION_RANGO_ETARIO(RANGO) VALUES ('<25')
	INSERT INTO NOT_FOUND.BI_DIMENSION_RANGO_ETARIO(RANGO) VALUES ('25-35')
	INSERT INTO NOT_FOUND.BI_DIMENSION_RANGO_ETARIO(RANGO) VALUES ('35-55')
	INSERT INTO NOT_FOUND.BI_DIMENSION_RANGO_ETARIO(RANGO) VALUES ('>55')
  END
GO

CREATE PROCEDURE NOT_FOUND.BI_migrar_productos
 AS
  BEGIN
    INSERT INTO NOT_FOUND.BI_DIMENSION_PRODUCTO(PRODUCTO_ID,NOMBRE_PRODUCTO,DESCRIPCION_PRODUCTO)
	SELECT PRODUCTO_CODIGO,PRODUCTO_NOMBRE,PRODUCTO_DESCRIPCION
	FROM NOT_FOUND.PRODUCTO 
  END
GO

CREATE PROCEDURE NOT_FOUND.BI_migrar_provincias
 AS
  BEGIN
    INSERT INTO NOT_FOUND.BI_DIMENSION_PROVINCIA(PROVINCIA_ID,PROVINCIA)
	SELECT PROVINCIA_CODIGO,PROVINCIA_DESCRIPCION
	FROM NOT_FOUND.PROVINCIA
  END
GO


CREATE PROCEDURE NOT_FOUND.BI_migrar_medios_de_pago
 AS
  BEGIN
	INSERT INTO NOT_FOUND.BI_DIMENSION_MEDIO_DE_PAGO(MEDIO_PAGO_ID,MEDIO_PAGO)
	SELECT MEDIO_PAGO_CODIGO,MEDIO_PAGO_DESCRIPCION
	FROM NOT_FOUND.MEDIO_PAGO
  END
GO

CREATE PROCEDURE NOT_FOUND.BI_migrar_canales
 AS
  BEGIN
	INSERT INTO NOT_FOUND.BI_DIMENSION_CANAL_DE_VENTA(CANAL_ID,CANAL,COSTO_CANAL)
	SELECT CANAL_CODIGO,CANAL_DESCRIPCION,CANAL_COSTO
	FROM NOT_FOUND.CANAL
  END
GO

CREATE PROCEDURE NOT_FOUND.BI_migrar_tipos_de_envio
 AS
  BEGIN
    INSERT INTO NOT_FOUND.BI_DIMENSION_TIPO_DE_ENVIO(TIPO_ENVIO_ID,TIPO_ENVIO)
	SELECT MEDIO_ENVIO_CODIGO,MEDIO_ENVIO_DESCRIPCION
	FROM NOT_FOUND.MEDIO_ENVIO
  END
GO



CREATE PROCEDURE NOT_FOUND.BI_migrar_tipos_de_descuento
 AS
  BEGIN
    INSERT INTO NOT_FOUND.BI_DIMENSION_TIPO_DE_DESCUENTO(TIPO_DESCUENTO_ID,TIPO_DESCUENTO)
	SELECT TIPO_DESCUENTO_CODIGO,TIPO_DESCUENTO_DESCRIPCION
	FROM NOT_FOUND.TIPO_DESCUENTO
  END
GO

CREATE PROCEDURE NOT_FOUND.BI_migrar_proveedores
 AS
  BEGIN
   INSERT INTO NOT_FOUND.BI_DIMENSION_PROVEEDOR(PROVEEDOR_ID,RAZON_SOCIAL,DOMICILIO,MAIL)
   SELECT PROVEEDOR_CUIT,PROVEEDOR_RAZON_SOCIAL,PROVEEDOR_DOMICILIO,PROVEEDOR_MAIL
   FROM NOT_FOUND.PROVEEDOR
  END
GO


CREATE PROCEDURE NOT_FOUND.BI_migrar_hechos_ventas
 AS
  BEGIN
   INSERT INTO NOT_FOUND.BI_HECHOS_VENTAS(CANAL_ID, MEDIO_PAGO_ID, TIPO_ENVIO_ID,PROVINCIA_ID, TIEMPO_ID, TOTAL_VENTA, PRECIO_PROM_MEDIO_ENVIO, COSTO_MEDIO_PAGO, CANTIDAD_DE_ENVIOS)
   SELECT VENTA_CANAL,VENTA_MEDIO_PAGO,VENTA_MEDIO_ENVIO,LOCALIDAD_PROVINCIA,TIEMPO_ID, SUM(VENTA_TOTAL), AVG(VENTA_MEDIO_ENVIO_PRECIO), SUM(VENTA_MEDIO_PAGO_COSTO), COUNT(*)
   FROM NOT_FOUND.VENTA JOIN NOT_FOUND.CLIENTE ON VENTA_CLIENTE = CLIENTE_CODIGO
						JOIN NOT_FOUND.LOCALIDAD ON CLIENTE_LOCALIDAD = LOCALIDAD_CODIGO 
						JOIN NOT_FOUND.BI_DIMENSION_TIEMPO ON YEAR(VENTA_FECHA) = A�O AND MONTH(VENTA_FECHA) = MES 
  GROUP BY VENTA_CANAL,VENTA_MEDIO_PAGO,VENTA_MEDIO_ENVIO,LOCALIDAD_PROVINCIA,TIEMPO_ID
  END
GO


CREATE PROCEDURE NOT_FOUND.BI_migrar_hechos_descuentos
 AS
  BEGIN
   INSERT INTO NOT_FOUND.BI_HECHOS_DESCUENTOS(CANAL_ID,TIPO_DESCUENTO_ID,MEDIO_PAGO_ID,TIEMPO_ID,IMPORTE)
   SELECT VENTA_CANAL, VENTA_DESCUENTO_TIPO, VENTA_MEDIO_PAGO, TIEMPO_ID, SUM(VENTA_DESCUENTO_IMPORTE)
   FROM NOT_FOUND.VENTA_DESCUENTO JOIN NOT_FOUND.VENTA ON VENTA_DESCUENTO_VENTA = VENTA_CODIGO
								  JOIN NOT_FOUND.BI_DIMENSION_TIEMPO ON YEAR(VENTA_FECHA) = A�O AND MONTH(VENTA_FECHA) = MES
   GROUP BY VENTA_CANAL, VENTA_DESCUENTO_TIPO, VENTA_MEDIO_PAGO, TIEMPO_ID
   UNION
   SELECT VENTA_CANAL, VENTA_CUPON_TIPO_DESCUENTO, VENTA_MEDIO_PAGO, TIEMPO_ID, SUM(VENTA_CUPON_IMPORTE)
   FROM NOT_FOUND.VENTA_CUPON JOIN NOT_FOUND.VENTA ON VENTA_CUPON_VENTA = VENTA_CODIGO
							  JOIN NOT_FOUND.BI_DIMENSION_TIEMPO ON YEAR(VENTA_FECHA) = A�O AND MONTH(VENTA_FECHA) = MES
   GROUP BY VENTA_CANAL, VENTA_CUPON_TIPO_DESCUENTO, VENTA_MEDIO_PAGO, TIEMPO_ID
  END
GO


CREATE PROCEDURE NOT_FOUND.BI_migrar_hechos_compras
 AS
  BEGIN
   INSERT INTO NOT_FOUND.BI_HECHOS_COMPRAS(PROVEEDOR_ID, PRODUCTO_ID, TIEMPO_ID, REPOSICION, PRECIO_MAXIMO, PRECIO_MINIMO, TOTAL_COMPRA)
   SELECT COMPRA_PROVEEDOR, PRODUCTO_VARIANTE_PRODUCTO, TIEMPO_ID, SUM(COMPRA_PRODUCTO_CANTIDAD), MAX(COMPRA_PRODUCTO_PRECIO), MIN(COMPRA_PRODUCTO_PRECIO), SUM(COMPRA_PRODUCTO_CANTIDAD * COMPRA_PRODUCTO_PRECIO)
   FROM NOT_FOUND.COMPRA_PRODUCTO JOIN NOT_FOUND.COMPRA ON COMPRA_PRODUCTO_COMPRA = COMPRA_NUMERO
                                  JOIN NOT_FOUND.PRODUCTO_VARIANTE ON COMPRA_PRODUCTO_PRODUCTO = PRODUCTO_VARIANTE_CODIGO
								  JOIN NOT_FOUND.BI_DIMENSION_TIEMPO ON YEAR(COMPRA_FECHA) = A�O AND MONTH(COMPRA_FECHA) = MES
   GROUP BY COMPRA_PROVEEDOR, PRODUCTO_VARIANTE_PRODUCTO, TIEMPO_ID
  END
GO

CREATE PROCEDURE NOT_FOUND.BI_migrar_hechos_productos_vendidos
 AS
  BEGIN
   INSERT INTO NOT_FOUND.BI_HECHOS_PRODUCTOS_VENDIDOS(RANGO_ETARIO_ID,PRODUCTO_ID,CATEGORIA_ID,TIEMPO_ID,UNIDADES,INGRESOS)
   SELECT RANGO_ETARIO_ID, PRODUCTO_CODIGO, PRODUCTO_CATEGORIA, TIEMPO_ID, SUM(VENTA_PRODUCTO_CANTIDAD), SUM(VENTA_PRODUCTO_PRECIO * VENTA_PRODUCTO_CANTIDAD)
   FROM NOT_FOUND.VENTA_PRODUCTO JOIN NOT_FOUND.VENTA ON VENTA_PRODUCTO_VENTA = VENTA_CODIGO
								 JOIN NOT_FOUND.CLIENTE ON VENTA_CLIENTE = CLIENTE_CODIGO
								 JOIN NOT_FOUND.PRODUCTO_VARIANTE ON VENTA_PRODUCTO_PRODUCTO = PRODUCTO_VARIANTE_CODIGO
								 JOIN NOT_FOUND.PRODUCTO ON PRODUCTO_VARIANTE_PRODUCTO = PRODUCTO_CODIGO
								 JOIN NOT_FOUND.BI_DIMENSION_TIEMPO ON YEAR(VENTA_FECHA) = A�O AND MONTH(VENTA_FECHA) = MES 
								 JOIN NOT_FOUND.BI_DIMENSION_RANGO_ETARIO ON RANGO = NOT_FOUND.rango_etario(CLIENTE_FECHA_NAC)

   GROUP BY RANGO_ETARIO_ID, PRODUCTO_CODIGO, PRODUCTO_CATEGORIA, TIEMPO_ID
  END
GO

------------------------

--CREACION DE VISTAS----

CREATE VIEW NOT_FOUND.BI_GANANCIAS_MENSUALES_POR_CANAL AS
	SELECT CANAL,T.A�O, T.MES, SUM(V.TOTAL_VENTA) - SUM(V.COSTO_MEDIO_PAGO) - (SELECT SUM(TOTAL_COMPRA)
	                                                                                FROM NOT_FOUND.BI_HECHOS_COMPRAS C 
		                                                                            WHERE C.TIEMPO_ID = V.TIEMPO_ID) GANANCIAS
	 FROM NOT_FOUND.BI_HECHOS_VENTAS V JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = V.TIEMPO_ID JOIN NOT_FOUND.BI_DIMENSION_CANAL_DE_VENTA CV ON V.CANAL_ID = CV.CANAL_ID
	 GROUP BY V.CANAL_ID, CANAL, V.TIEMPO_ID, T.A�O, T.MES
GO


CREATE VIEW NOT_FOUND.BI_PRODUCTOS_CON_MAYOR_RENTABILIDAD_ANUAL AS
	SELECT NOMBRE_PRODUCTO, T.A�O, (SUM(INGRESOS) - (SELECT SUM(TOTAL_COMPRA) 
																  FROM NOT_FOUND.BI_HECHOS_COMPRAS C JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T2 ON T2.TIEMPO_ID = C.TIEMPO_ID 
																  WHERE C.PRODUCTO_ID = PV.PRODUCTO_ID AND T2.A�O = T.A�O 
																  GROUP BY C.PRODUCTO_ID)) / SUM(INGRESOS) *100 RENTABILIDAD_ANUAL
	FROM  NOT_FOUND.BI_HECHOS_PRODUCTOS_VENDIDOS PV JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = PV.TIEMPO_ID JOIN NOT_FOUND.BI_DIMENSION_PRODUCTO P ON P.PRODUCTO_ID = PV.PRODUCTO_ID
	GROUP BY PV.PRODUCTO_ID, NOMBRE_PRODUCTO, T.A�O
	HAVING PV.PRODUCTO_ID IN (SELECT TOP 5 PV2.PRODUCTO_ID 
							  FROM  NOT_FOUND.BI_HECHOS_PRODUCTOS_VENDIDOS PV2 -- JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T3 ON T3.TIEMPO_ID = PV2.TIEMPO_ID 
						   -- WHERE T3.A�O = T.A�O
							  GROUP BY PV2.PRODUCTO_ID --, T3.A�O
							  ORDER BY (SUM(INGRESOS) - (SELECT SUM(TOTAL_COMPRA) 
																          FROM NOT_FOUND.BI_HECHOS_COMPRAS C -- JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T4 ON T4.TIEMPO_ID = C.TIEMPO_ID 
																          WHERE C.PRODUCTO_ID = PV2.PRODUCTO_ID -- AND T4.A�O = T3.A�O
																		  GROUP BY C.PRODUCTO_ID)) / SUM(INGRESOS) DESC)
GO

CREATE VIEW NOT_FOUND.BI_CATEGORIAS_DE_PROD_MAS_VEND_POR_RANGO_ETARIO_Y_MES AS
	SELECT RANGO, T.MES, T.A�O, CATEGORIA, SUM(UNIDADES) PRODUCTOS_VENDIDOS
	FROM NOT_FOUND.BI_HECHOS_PRODUCTOS_VENDIDOS PV JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = PV.TIEMPO_ID 
												   JOIN NOT_FOUND.BI_DIMENSION_RANGO_ETARIO R ON R.RANGO_ETARIO_ID = PV.RANGO_ETARIO_ID
												   JOIN NOT_FOUND.BI_DIMENSION_CATEGORIA C ON C.CATEGORIA_ID = PV.CATEGORIA_ID
	GROUP BY PV.CATEGORIA_ID, CATEGORIA, PV.RANGO_ETARIO_ID, RANGO, CATEGORIA, T.MES, T.A�O, PV.TIEMPO_ID
	HAVING PV.CATEGORIA_ID IN (SELECT TOP 5 CATEGORIA_ID FROM NOT_FOUND.BI_HECHOS_PRODUCTOS_VENDIDOS WHERE TIEMPO_ID = PV.TIEMPO_ID AND RANGO_ETARIO_ID = PV.RANGO_ETARIO_ID GROUP BY CATEGORIA_ID ORDER BY SUM(UNIDADES) DESC)

GO

CREATE VIEW NOT_FOUND.BI_INGRESOS_MENSUALES_POR_MEDIOS_DE_PAGO AS
	SELECT MEDIO_PAGO, T.MES, T.A�O, SUM(TOTAL_VENTA) - SUM(COSTO_MEDIO_PAGO) - (SELECT ISNULL(SUM(IMPORTE),0)
																					  FROM NOT_FOUND.BI_HECHOS_DESCUENTOS D 
																					  JOIN NOT_FOUND.BI_DIMENSION_TIPO_DE_DESCUENTO TD ON D.TIPO_DESCUENTO_ID =  TD.TIPO_DESCUENTO_ID
																					  WHERE D.MEDIO_PAGO_ID = V.MEDIO_PAGO_ID AND TD.TIPO_DESCUENTO = 'Medio de pago' AND D.TIEMPO_ID = V.TIEMPO_ID) 
																					  AS INGRESOS
	FROM NOT_FOUND.BI_HECHOS_VENTAS V JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = V.TIEMPO_ID JOIN NOT_FOUND.BI_DIMENSION_MEDIO_DE_PAGO M ON M.MEDIO_PAGO_ID = V.MEDIO_PAGO_ID
	GROUP BY V.MEDIO_PAGO_ID, MEDIO_PAGO, T.MES, T.A�O, V.TIEMPO_ID
GO

CREATE VIEW NOT_FOUND.BI_IMPORTE_TOTAL_POR_TIPOS_DE_DESCUENTO AS
	SELECT TIPO_DESCUENTO, CANAL,T.MES, T.A�O, SUM(IMPORTE) TOTAL_IMPORTE
	FROM NOT_FOUND.BI_HECHOS_DESCUENTOS D JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = D.TIEMPO_ID 
										  JOIN NOT_FOUND.BI_DIMENSION_TIPO_DE_DESCUENTO TD ON TD.TIPO_DESCUENTO_ID = D.TIPO_DESCUENTO_ID 
										  JOIN NOT_FOUND.BI_DIMENSION_CANAL_DE_VENTA CV ON CV.CANAL_ID = D.CANAL_ID
	GROUP BY D.TIPO_DESCUENTO_ID, TIPO_DESCUENTO,D.CANAL_ID,CANAL, T.MES, T.A�O
	
GO

CREATE VIEW NOT_FOUND.BI_PORCENTAJE_DE_ENVIOS_POR_PROVINCIA AS
	SELECT PROVINCIA, MES, A�O, CONVERT(DECIMAL(18,0),SUM(CANTIDAD_DE_ENVIOS)) / (SELECT SUM(CANTIDAD_DE_ENVIOS)
																      FROM NOT_FOUND.BI_HECHOS_VENTAS V2 
																	  WHERE V2.TIEMPO_ID = V.TIEMPO_ID) * 100 AS PORCENTAJE_DE_ENVIOS
	FROM NOT_FOUND.BI_HECHOS_VENTAS V JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = V.TIEMPO_ID
									  JOIN NOT_FOUND.BI_DIMENSION_PROVINCIA P ON P.PROVINCIA_ID = V.PROVINCIA_ID
	GROUP BY V.PROVINCIA_ID, PROVINCIA, MES, A�O, V.TIEMPO_ID
	
GO

CREATE VIEW NOT_FOUND.BI_VALOR_PROMEDIO_ANUAL_DE_ENVIO_POR_PROVINCIA_POR_TIPO_DE_ENVIO AS
	SELECT PROVINCIA, TIPO_ENVIO, A�O, AVG(PRECIO_PROM_MEDIO_ENVIO) AS VALOR_PROMEDIO_DE_ENVIO
	FROM NOT_FOUND.BI_HECHOS_VENTAS V JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = V.TIEMPO_ID
									  JOIN NOT_FOUND.BI_DIMENSION_PROVINCIA P ON P.PROVINCIA_ID = V.PROVINCIA_ID
									  JOIN NOT_FOUND.BI_DIMENSION_TIPO_DE_ENVIO E ON E.TIPO_ENVIO_ID = V.TIPO_ENVIO_ID
	GROUP BY V.PROVINCIA_ID, PROVINCIA, V.TIPO_ENVIO_ID, TIPO_ENVIO, A�O
GO

CREATE VIEW NOT_FOUND.BI_AUMENTO_PROMEDIO_DE_PRECIOS_ANUAL_DE_PROVEEDORES AS
	SELECT RAZON_SOCIAL, PRODUCTO_ID, A�O, (MAX(PRECIO_MAXIMO) - MIN(PRECIO_MINIMO))/MIN(PRECIO_MINIMO) AS AUMENTO_PROMEDIO_DE_PRECIO
	FROM NOT_FOUND.BI_HECHOS_COMPRAS C JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = C.TIEMPO_ID
									   JOIN NOT_FOUND.BI_DIMENSION_PROVEEDOR P ON P.PROVEEDOR_ID = C.PROVEEDOR_ID
	GROUP BY C.PROVEEDOR_ID, RAZON_SOCIAL, PRODUCTO_ID, A�O
GO

CREATE VIEW NOT_FOUND.BI_3_PRODUCTOS_CON_MAYOR_REPOSICION_POR_MES AS
	SELECT NOMBRE_PRODUCTO, T.MES, T.A�O, SUM(REPOSICION) REPOSICION
	FROM NOT_FOUND.BI_HECHOS_COMPRAS C JOIN NOT_FOUND.BI_DIMENSION_TIEMPO T ON T.TIEMPO_ID = C.TIEMPO_ID
									   JOIN NOT_FOUND.BI_DIMENSION_PRODUCTO P ON P.PRODUCTO_ID = C.PRODUCTO_ID
	GROUP BY C.PRODUCTO_ID, NOMBRE_PRODUCTO, T.MES, T.A�O, C.TIEMPO_ID
	HAVING C.PRODUCTO_ID IN (SELECT TOP 3 PRODUCTO_ID 
							 FROM NOT_FOUND.BI_HECHOS_COMPRAS 
						   --WHERE TIEMPO_ID = C.TIEMPO_ID 
							 GROUP BY PRODUCTO_ID 
							 ORDER BY SUM(REPOSICION) DESC)
GO
 
--------------------------------------------------------

--Ejecucion de procedures migracion
BEGIN TRANSACTION

	EXECUTE NOT_FOUND.BI_migrar_canales
	EXECUTE NOT_FOUND.BI_migrar_tiempos
	EXECUTE NOT_FOUND.BI_migrar_categorias
	EXECUTE NOT_FOUND.BI_migrar_rangos_etarios
	EXECUTE NOT_FOUND.BI_migrar_productos
	EXECUTE NOT_FOUND.BI_migrar_provincias
	EXECUTE NOT_FOUND.BI_migrar_medios_de_pago
	EXECUTE NOT_FOUND.BI_migrar_tipos_de_envio
	EXECUTE NOT_FOUND.BI_migrar_tipos_de_descuento
	EXECUTE NOT_FOUND.BI_migrar_proveedores
	EXECUTE NOT_FOUND.BI_migrar_hechos_ventas
	EXECUTE NOT_FOUND.BI_migrar_hechos_descuentos
	EXECUTE NOT_FOUND.BI_migrar_hechos_compras
	EXECUTE NOT_FOUND.BI_migrar_hechos_productos_vendidos

COMMIT TRANSACTION
GO
