/****** Object:  Table [dbo].[Coupons]    Script Date: 05/17/2012 14:14:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Coupons](
	[CouponID] [int] IDENTITY(1,1) NOT NULL,
	[CouponCode] [varchar](50) NOT NULL,
	[CouponName] [varchar](50) NOT NULL,
	[Description] [varchar](4000) NULL,
	[Percentage] [decimal](18, 4) NULL,
	[Amount] [money] NULL,
	[ExpirationDate] [datetime] NULL,
	[Active] [smallint] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Coupons] PRIMARY KEY CLUSTERED 
(
	[CouponID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Categories]    Script Date: 05/17/2012 14:14:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Categories](
	[CategoryID] [int] IDENTITY(1,1) NOT NULL,
	[ParentID] [int] NULL,
	[CategoryName] [varchar](50) NOT NULL,
	[Description] [varchar](6000) NULL,
	[Active] [smallint] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
	[ImagePath1] [varchar](255) NULL,
	[ImagePath2] [varchar](255) NULL,
	[ImagePath1Hip] [varchar](255) NULL,
	[ImagePath2Hip] [varchar](255) NULL,
	[OldCategoryID] [int] NULL,
	[OldParentID] [int] NULL,
 CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED 
(
	[CategoryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[NewsletterSubscriptions]    Script Date: 05/17/2012 14:14:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[NewsletterSubscriptions](
	[SiteID] [int] NOT NULL,
	[Email] [varchar](255) NOT NULL,
	[Name] [varchar](150) NULL,
	[SignupDate] [datetime] NOT NULL,
	[SignupIP] [varchar](16) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_List]    Script Date: 05/17/2012 14:14:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_List]
	@SiteID				Integer = NULL,
	@CategoryID			Integer = NULL,
	@SearchText			Varchar(100) = NULL,
	@SoldOut			Smallint = NULL,
	@Active				Smallint = NULL,
	@System				Smallint = NULL,
	@WithSold			Smallint = NULL,
	@WithOffline		Smallint = NULL,
	@PageIndex			Integer = 0,
	@MaxPerPage			Integer = NULL,
	@MaxRowsTotal		Integer = 0,
	@SortBy				Varchar(20) = 'Product Name',
	@SortDir			Tinyint = 0,
	@ShowReducedPrice	SMALLINT=NULL,
	@ShowFeatured		SMALLINT=NULL,
	@RelProductID		INTEGER=NULL,
	@ShowHomePage		SMALLINT=NULL				
AS

SET NOCOUNT ON

-- Setup defaults for paging
IF @PageIndex IS NULL SET @PageIndex = 0
IF @PageIndex < 0 SET @PageIndex = 0

-- Create the temp table for identity values
CREATE TABLE #Products
(
	ProductID	Integer,
	DisplayOrder	Integer Identity
)

-- Make sure there is no row limit
SET ROWCOUNT @MaxRowsTotal

-- Load all matching Products into temp table
INSERT INTO #Products (ProductID)
SELECT
	P.ProductID
FROM
	Products P
	INNER JOIN Categories C ON P.CategoryID = C.CategoryID
	LEFT OUTER JOIN Categories PC ON C.ParentID = PC.CategoryID
	LEFT OUTER JOIN SiteProducts SP ON P.ProductID = SP.ProductID
	LEFT OUTER JOIN 
		(SELECT @CategoryID AS CategoryID UNION 
		 SELECT CategoryID FROM Categories WHERE ParentID = @CategoryID) C2
		 ON P.CategoryID = C2.CategoryID
WHERE
	ISNULL(SP.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(SP.SiteID, 0) ELSE @SiteID END) AND
	P.CategoryID = (CASE WHEN @CategoryID IS NULL THEN P.CategoryID ELSE C2.CategoryID END) AND
	(CASE 	WHEN @SearchText IS NULL THEN 1
		WHEN P.ProductCode = @SearchText THEN 1
		WHEN P.ProductName = @SearchText THEN 1
		WHEN P.ProductCode LIKE '%' + @SearchText THEN 1
		WHEN P.ProductCode LIKE '%' + @SearchText + '%' THEN 1
		WHEN P.ProductCode LIKE @SearchText + '%' THEN 1
		WHEN P.ProductName LIKE '%' + @SearchText THEN 1
		WHEN P.ProductName LIKE '%' + @SearchText + '%' THEN 1
		WHEN P.ProductName LIKE @SearchText + '%' THEN 1
		WHEN CHARINDEX('[' + @SearchText + ']', P.Keywords) > 0 THEN 1
		ELSE 0
	 END) = 1 AND
	(CASE	WHEN @SoldOut IS NULL THEN 1
		WHEN @SoldOut = 0 AND ISNULL(P.Inventory, 1) > 0 THEN 1
		WHEN @SoldOut = 0 AND ISNULL(P.Inventory, 1) <= 0 AND P.AllowBackorder = 1 THEN 1
		WHEN @SoldOut = 1 AND ISNULL(P.Inventory, 1) <= 0 AND P.AllowBackorder <> 1 THEN 1		
	 END) = 1 AND
	(CASE WHEN @WithOffline = 0 AND C.CategoryName = 'Offline' THEN 0 ELSE 1 END) = 1 AND
	P.System = (CASE WHEN @System IS NULL THEN P.System ELSE @System END) AND
	P.Active = (CASE WHEN @Active IS NULL THEN P.Active ELSE @Active END) AND
	P.Active > -1 AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1 AND
	(CASE	WHEN @Active IS NOT NULL AND PC.Active IS NOT NULL AND PC.Active = @Active THEN 1
		WHEN @Active IS NOT NULL AND PC.Active IS NULL THEN 1
		WHEN @Active IS NULL THEN 1
		ELSE 0
	 END) = 1 AND
	ISNULL(PC.Active, 0) > -1
	AND	1 = (CASE
				WHEN @ShowReducedPrice IS NULL THEN 1
				WHEN P.ShowReducedPrice = @ShowReducedPrice THEN 1
				ELSE 0 
			 END)
	AND 1 = (CASE
				WHEN @ShowFeatured IS NULL THEN 1
				WHEN P.ShowFeatured = @ShowFeatured THEN 1
				ELSE 0
			 END)
	AND 1 = (CASE
				WHEN @RelProductID IS NULL THEN 1
				WHEN @RelProductID IS NOT NULL AND (P.ProductID <> @RelProductID) THEN 1
				ELSE 0
			 END )
	AND 1 = (CASE
				WHEN @ShowHomePage IS NULL THEN 1
				WHEN P.ShowHomePage = @ShowHomePage THEN 1
				ELSE 0
			 END )
GROUP BY
	P.ProductID,
	P.ProductCode,
	P.ProductName,
	P.Wrapper,
	P.Cost,
	P.RetailPrice,
	P.OriginalPrice,
	P.Weight,
	P.Inventory,
	P.CreateDate,
	P.OldCategoryID
	
ORDER BY
	(CASE	WHEN @SortBy = 'Product Code' AND @SortDir = 0 THEN P.ProductCode
		WHEN @SortBy = 'Product Name' AND @SortDir = 0 THEN P.ProductName
		ELSE NULL
	 END) ASC,
	(CASE	WHEN @SortBy = 'Cost' AND @SortDir = 0 THEN P.Cost
		WHEN @SortBy = 'Retail Price' AND @SortDir = 0 THEN P.RetailPrice
		WHEN @SortBy = 'Original Price' AND @SortDir = 0 THEN P.OriginalPrice
		WHEN @SortBy = 'Weight' AND @SortDir = 0 THEN P.Weight
		WHEN @SortBy = 'Inventory' AND @SortDir = 0 THEN P.Inventory
		ELSE NULL
	 END) ASC,
	(CASE	WHEN @SortBy = 'Date' AND @SortDir = 0 THEN P.CreateDate
		ELSE NULL
	 END) ASC,
	(CASE	WHEN @SortBy = 'Date' AND @SortDir = 0 THEN P.ProductID
		ELSE NULL
	 END) ASC,
	(CASE WHEN @SortBy = 'Wrapper' AND @SortDir = 0 THEN P.Wrapper ELSE NULL END) ASC,
	(CASE WHEN @SortBy = 'Custom' AND @SortDir = 0 THEN P.OldCategoryID ELSE NULL END) ASC,
	(CASE WHEN @SortBy = 'Custom' AND @SortDir = 1 THEN P.OldCategoryID ELSE NULL END) DESC,
	(CASE	WHEN @SortBy = 'Product Code' AND @SortDir = 1 THEN P.ProductCode
		WHEN @SortBy = 'Product Name' AND @SortDir = 1 THEN P.ProductName
		ELSE NULL
	 END) DESC,
	(CASE	WHEN @SortBy = 'Cost' AND @SortDir = 1 THEN P.Cost
		WHEN @SortBy = 'Retail Price' AND @SortDir = 1 THEN P.RetailPrice
		WHEN @SortBy = 'Original Price' AND @SortDir = 1 THEN P.OriginalPrice
		WHEN @SortBy = 'Weight' AND @SortDir = 1 THEN P.Weight
		WHEN @SortBy = 'Inventory' AND @SortDir = 1 THEN P.Inventory
		ELSE NULL
	 END) DESC,
	(CASE	WHEN @SortBy = 'Date' AND @SortDir = 1 THEN P.CreateDate
		ELSE NULL
	 END) DESC,
	(CASE	WHEN @SortBy = 'Date' AND @SortDir = 1 THEN P.ProductID
		ELSE NULL
	 END) DESC,
	(CASE WHEN @SortBy = 'Wrapper' AND @SortDir = 1 THEN P.Wrapper ELSE NULL END) DESC

CREATE TABLE #Sold
(
	ProductID Integer,
	Sold Integer
)

IF @WithSold = 1
	BEGIN
	INSERT INTO #Sold
	SELECT
		P.ProductID,
		SUM(Quantity)
	FROM
		#Products P
		INNER JOIN OrderItems OI ON P.ProductID = OI.ProductID
		INNER JOIN Orders O ON OI.OrderID = O.OrderID
	WHERE
		P.DisplayOrder > (@PageIndex * ISNULL(@MaxPerPage, 0))
	GROUP BY
		P.ProductID,
		P.DisplayOrder
	ORDER BY
		P.DisplayOrder
	END
	
IF @MaxPerPage IS NOT NULL SET ROWCOUNT @MaxPerPage
SET NOCOUNT OFF
SELECT
	P.ProductID,
	PC.CategoryID AS ParentCategoryID,
	PC.CategoryName AS ParentCategoryName,
	C.CategoryID,
	C.CategoryName,
	(CASE	WHEN PC.CategoryID IS NULL THEN C.CategoryName
		WHEN PC.CategoryID IS NOT NULL THEN PC.CategoryName + ' > ' + C.CategoryName
	 END) AS CategoryNameFull,
	P.ProductCode,
	P.ProductName,
	P.Length,
	P.Ring,
	P.AmountPerBox,
	P.Wrapper,
	P.Description,
	P.ImagePath1,	
	P.Cost,
	P.RetailPrice,
	P.OriginalPrice,
	P.Inventory,
	S.Sold,
	P.AllowBackorder,
	P.ShowNew,
	P.ShowReducedPrice,
	P.ShowFeatured,
	P.System,
	P.Active,
	P.OldCategoryID,
	(CASE WHEN ISNULL(OP.OptionCount, 0) > 0 THEN 1 ELSE 0 END) AS HasOptions,

	--> Featured product control fields
	P.ImagePath7,
	P.ImagePath8,
	P.FeaturedTitle,
	P.FeaturedSubTitle,
	P.FeaturedBullet1,
	P.FeaturedBullet2,
	P.FeaturedBullet3

FROM
	Products P
	INNER JOIN #Products P2 ON P.ProductID = P2.ProductID
	INNER JOIN Categories C ON P.CategoryID = C.CategoryID
	LEFT OUTER JOIN Categories PC ON C.ParentID = PC.CategoryID
	LEFT OUTER JOIN #Sold S ON P.ProductID = S.ProductID
	LEFT OUTER JOIN
		(SELECT
			ProductID,
			COUNT(1) AS OptionCount
		 FROM
			ProductOptions
		 GROUP BY
			ProductID) AS OP ON P.ProductiD = OP.ProductID
WHERE
	P2.DisplayOrder > (@PageIndex * ISNULL(@MaxPerPage, 0))
ORDER BY
	P2.DisplayOrder

SELECT
	COUNT(1) AS TotalRecords
FROM
	#Products
	
DROP TABLE #Products
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_List]    Script Date: 05/17/2012 14:14:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_Orders_List]
	@PendingPayment		Tinyint = 1,
	@PendingShipment	Tinyint = 1,
	@Backordered		Tinyint = 1,
	@Completed		Tinyint = 1,
	@Incomplete		Tinyint = 1,
	@Voided			Tinyint = 1,
	@Domestic		Tinyint = 1,
	@International		Tinyint = 1,
	@CustomFilter		Varchar(1000) = NULL,
	@StartDate		Datetime = NULL,
	@EndDate		Datetime = NULL,
	@PageIndex		Integer = NULL,
	@MaxPerPage		Integer = NULL,
	@SortBy			Varchar(20) = 'Order Number',
	@SortDir		Tinyint = 0
AS

SET NOCOUNT ON

-- Setup defaults for paging
IF @PageIndex IS NULL SET @PageIndex = 0
IF @PageIndex < 0 SET @PageIndex = 0

-- Create the temp table for identity values
CREATE TABLE #Orders
(
	OrderID		Integer,
	DisplayOrder	Integer Identity
)
CREATE TABLE #Filter 
(
	OrderID		Integer
)

-- Make sure there is no row limit
SET ROWCOUNT 0

IF @CustomFilter IS NOT NULL
	BEGIN
	EXEC('INSERT INTO #Filter SELECT OrderID FROM Orders WHERE ' + @CustomFilter)
	END

-- Load all matching orders into temp table
INSERT INTO #Orders (OrderID)
SELECT
	O.OrderID
FROM
	Orders O
	LEFT OUTER JOIN #Filter F ON O.OrderID = F.OrderID
WHERE
	(CASE 	WHEN O.Status = 'Pending Payment' AND @PendingPayment = 1 THEN 1
		WHEN O.Status = 'Pending Shipment' AND @PendingShipment = 1 THEN 1
		WHEN O.Status = 'Backordered' AND @Backordered = 1 THEN 1
		WHEN O.Status = 'Completed' AND @Completed = 1 THEN 1
		WHEN O.Status = 'Incomplete' AND @Incomplete = 1 THEN 1
		WHEN O.Status = 'Voided' AND @Voided = 1 THEN 1
		ELSE 0
	 END) = 1 AND
	(CASE	WHEN @Domestic = 1 AND O.ShipCountry = 'United States' THEN 1
		WHEN @International = 1 AND O.ShipCountry <> 'United States' THEN 1
		ELSE 0
	 END) = 1 AND
	(CASE	WHEN @CustomFilter IS NOT NULL AND F.OrderID IS NOT NULL THEN 1
		WHEN @CustomFilter IS NULL THEN 1
		ELSE 0
	 END) = 1 AND
	O.CreateDate BETWEEN ISNULL(@StartDate, '1/1/1900') AND ISNULL(@EndDate, '12/31/9999')
ORDER BY
	(CASE	WHEN @SortBy = 'Order Date' AND @SortDir = 0 THEN O.CreateDate ELSE NULL END) ASC,
	(CASE	WHEN @SortBy = 'Order Number' AND @SortDir = 0 THEN O.OrderID
		WHEN @SortBy = 'Order Total' AND @SortDir = 0 THEN O.GrandTotal
		ELSE NULL
	 END) ASC,
	(CASE	WHEN @SortBy = 'Order Status' AND @SortDir = 0 THEN O.Status
		WHEN @SortBy = 'Customer Name' AND @SortDir = 0 THEN O.FirstName + ' ' + LastName
		WHEN @SortBy = 'Customer Email' AND @SortDir = 0 THEN O.Email
		WHEN @SortBy = 'Payment Method' AND @SortDir = 0 THEN O.PaymentMethod
		ELSE NULL
	 END) ASC,
	(CASE	WHEN @SortBy = 'Order Date' AND @SortDir = 1 THEN O.CreateDate
		WHEN @SortBy = 'Order Number' AND @SortDir = 1 THEN O.OrderID
		WHEN @SortBy = 'Order Status' AND @SortDir = 1 THEN O.Status
		WHEN @SortBy = 'Customer Name' AND @SortDir = 1 THEN O.FirstName + ' ' + O.LastName
		WHEN @SortBy = 'Customer Email' AND @SortDir = 1 THEN O.Email
		WHEN @SortBy = 'Payment Method' AND @SortDir = 1 THEN O.PaymentMethod
		WHEN @SortBy = 'Order Total' AND @SortDir = 1 THEN O.GrandTotal
		ELSE NULL
	 END) DESC,
	 (CASE	WHEN @SortBy = 'Order Date' AND @SortDir = 1 THEN O.CreateDate ELSE NULL END) DESC,
	 (CASE	WHEN @SortBy = 'Order Number' AND @SortDir = 1 THEN O.OrderID
		WHEN @SortBy = 'Order Total' AND @SortDir = 1 THEN O.GrandTotal
		ELSE NULL
	 END) DESC,
	 (CASE	WHEN @SortBy = 'Order Status' AND @SortDir = 1 THEN O.Status
		WHEN @SortBy = 'Customer Name' AND @SortDir = 1 THEN O.FirstName + ' ' + O.LastName
		WHEN @SortBy = 'Customer Email' AND @SortDir = 1 THEN O.Email
		WHEN @SortBy = 'Payment Method' AND @SortDir = 1 THEN O.PaymentMethod
		ELSE NULL
	 END) DESC

IF @MaxPerPage IS NOT NULL SET ROWCOUNT @MaxPerPage
SET NOCOUNT OFF
SELECT
	O.OrderID,
	S.SiteID,
	S.SiteCode,
	S.SiteName,
	O.FirstName + ' ' + O.LastName AS BuyerName,
	O.FirstName,
	O.LastName,
	O.Email,
	O.ShipAddress1,
	O.ShipAddress2,
	O.ShipCity,
	O.ShipState,
	O.ShipPostalCode,
	O.ShipCountry,
	O.Phone,
	O.CardNumber,
	O.CardAuthCode,
	O.ShipTracking,
	O.PaymentMethod,
	(CASE WHEN O.CardType IS NULL THEN O.PaymentMethod ELSE O.CardType END) AS PayType,
	O.GrandTotal,
	O.Status,
	O.CreateDate
FROM
	Orders O
	INNER JOIN #Orders O2 ON O.OrderID = O2.OrderID
	INNER JOIN Sites S ON O.SiteID = S.SiteID	
WHERE
	O2.DisplayOrder > (@PageIndex * ISNULL(@MaxPerPage, 0))
ORDER BY
	O2.DisplayOrder

SELECT
	COUNT(1) AS TotalRecords
FROM
	#Orders

DROP TABLE #Orders
GO
/****** Object:  StoredProcedure [dbo].[sp_NewsletterSubscription_Get]    Script Date: 05/17/2012 14:14:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_NewsletterSubscription_Get]
	@StartDate DATETIME,
	@EndDate DATETIME,
	@Sites VARCHAR(1000)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT 
		N.Name,
		N.Email,
		S.SiteName,
		N.SignupDate,
		N.SignupIP
	FROM
		NewsletterSubscriptions N
	INNER JOIN
		Sites S ON N.SiteID = S.SiteID
	WHERE
		N.SignupDate >= @StartDate AND
		N.SignupDate <= @EndDate AND
		N.SiteID IN (SELECT Data FROM fnParseList(',',@Sites))
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Coupons_List]    Script Date: 05/17/2012 14:14:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Coupons_List]
	@Active		Smallint = NULL,
	@PageIndex	Integer = 0,
	@MaxPerPage	Integer = NULL
AS

SET NOCOUNT ON

-- Setup defaults for paging
IF @PageIndex IS NULL SET @PageIndex = 0
IF @PageIndex < 0 SET @PageIndex = 0

-- Create the temp table for identity values
CREATE TABLE #Coupons
(
	CouponID	Integer,
	DisplayOrder	Integer Identity
)

-- Make sure there is no row limit
SET ROWCOUNT 0

-- Load all matching Coupons into temp table
INSERT INTO #Coupons (CouponID)
SELECT
	C.CouponID
FROM
	Coupons C
WHERE
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1
ORDER BY
	C.CouponName

SET ROWCOUNT @MaxPerPage
SET NOCOUNT OFF
SELECT
	C.CouponID,
	C.CouponCode,
	C.CouponName,
	C.[Description],
	C.Percentage,
	C.Amount,
	C.ExpirationDate,
	COUNT(O.OrderID) AS TimesUsed,
	C.Active,
	C.CreateDate,
	C.ModifyDate
FROM
	Coupons C
	INNER JOIN #Coupons C2 ON C.CouponID = C2.CouponID
	LEFT OUTER JOIN Orders O ON C.CouponID = O.CouponID
WHERE
	C2.DisplayOrder > (@PageIndex * ISNULL(@MaxPerPage, 0))
GROUP BY
	C.CouponID,
	C.CouponCode,
	C.CouponName,
	C.[Description],
	C.Percentage,
	C.Amount,
	C.ExpirationDate,
	C.Active,
	C.CreateDate,
	C.ModifyDate,
	C2.DisplayOrder
ORDER BY
	C2.DisplayOrder

SELECT
	COUNT(1) AS TotalRecords
FROM
	#Coupons
	
DROP TABLE #Coupons
GO
/****** Object:  Table [dbo].[Users]    Script Date: 05/17/2012 14:14:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Users](
	[UserID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Username] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[AccessLevel] [int] NULL,
	[Active] [int] NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[dtproperties]    Script Date: 05/17/2012 14:14:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dtproperties](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[objectid] [int] NULL,
	[property] [varchar](64) NOT NULL,
	[value] [varchar](255) NULL,
	[uvalue] [nvarchar](255) NULL,
	[lvalue] [image] NULL,
	[version] [int] NOT NULL,
 CONSTRAINT [pk_dtproperties] PRIMARY KEY CLUSTERED 
(
	[id] ASC,
	[property] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[ConvertIntListToTable]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConvertIntListToTable] (@Values NText)
	RETURNS @Result TABLE (Value Integer NOT NULL) AS
BEGIN

DECLARE	@Pos      Integer,
	@TextPos  Integer,
	@ChunkLen Smallint,
	@Str      NVarchar(4000),
	@TmpStr   NVarchar(4000),
	@LeftOver NVarchar(4000)

SET @TextPos = 1
SET @LeftOver = ''
WHILE @TextPos <= DATALENGTH(@Values) / 2
BEGIN
	SET @ChunkLen = 4000 - DATALENGTH(@LeftOver) / 2
	SET @TmpStr = LTRIM(@LeftOver + SUBSTRING(@Values, @TextPos, @ChunkLen))
	SET @TextPos = @TextPos + @ChunkLen
	
	SET @Pos = CHARINDEX(',', @TmpStr)
	WHILE @Pos > 0
	BEGIN
		SET @Str = SUBSTRING(@TmpStr, 1, @Pos - 1)
		INSERT @Result (Value) VALUES(CONVERT(Integer, @Str))
		SET @TmpStr = LTRIM(SUBSTRING(@TmpStr, @Pos + 1, LEN(@TmpStr)))
		SET @Pos = CHARINDEX(',', @TmpStr)
	END
	
	SET @LeftOver = @TmpStr
END

IF LTRIM(RTRIM(@LeftOver)) <> '' 
INSERT @Result (Value) VALUES(CONVERT(Integer, @LeftOver))

RETURN
END
GO
/****** Object:  Table [dbo].[Settings]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Settings](
	[SettingID] [int] IDENTITY(1,1) NOT NULL,
	[SettingType] [varchar](50) NOT NULL,
	[SettingValue] [varchar](500) NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Settings] PRIMARY KEY CLUSTERED 
(
	[SettingID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_ListSummaryCounts]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_ListSummaryCounts] AS
	
SELECT	
	COUNT(1) AS [Count]
FROM
	Products
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductPriceRanges_Delete]
(
	 @ProductPriceRangeID INTEGER
)	
	
AS
BEGIN
	SET NOCOUNT ON

	DELETE FROM ProductPriceRanges
	WHERE ProductPriceRangeID = @ProductPriceRangeID
	
	RETURN
END
GO
/****** Object:  Table [dbo].[ProductPriceRanges]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductPriceRanges](
	[ProductPriceRangeID] [int] IDENTITY(1,1) NOT NULL,
	[ProductID] [int] NOT NULL,
	[LowerLimit] [int] NULL,
	[Limit] [int] NOT NULL,
	[Price] [money] NOT NULL,
	[Active] [int] NOT NULL,
 CONSTRAINT [PK_ProductPriceRanges] PRIMARY KEY CLUSTERED 
(
	[ProductPriceRangeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_ListByLimit]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductPriceRanges_ListByLimit]
(
	 @ProductID		INTEGER
	,@Limit			INTEGER
) AS
BEGIN
	SELECT
		 ProductPriceRangeID
		,ProductID
		,LowerLimit
		,Limit
		,Price
		,Active
	FROM
		ProductPriceRange
	WHERE
		ProductID = @ProductID
	AND Limit = @Limit

	RETURN
END
GO
/****** Object:  Table [dbo].[CustomContent]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CustomContent](
	[ContentID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[SiteID] [int] NULL,
	[Title] [varchar](255) NULL,
	[Content] [text] NULL,
	[Active] [int] NULL,
	[DateCreated] [datetime] NULL,
 CONSTRAINT [PK_CustomContent] PRIMARY KEY CLUSTERED 
(
	[ContentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_SetInventory]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_SetInventory]
	@ProductID	Integer,
	@Inventory	Integer
AS

UPDATE
	Products
SET
	Inventory = @Inventory,
	ModifyDate = GetDate()
WHERE
	ProductID = @ProductID
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_ListParent]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_ListParent]
	@SiteID Integer = NULL,
	@RootCat int = NULL,
	@MaxPerPage int = 999,
	@PageIndex int = 0
AS

-- Setup defaults for paging
IF @PageIndex IS NULL SET @PageIndex = 0
IF @PageIndex < 0 SET @PageIndex = 0

CREATE TABLE #Categories (
	CategoryID int,
	DisplayOrder int identity
)

INSERT INTO #Categories( CategoryID )
SELECT
	C.CategoryID
FROM
	Categories C
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
WHERE
	(CASE WHEN @SiteID IS NULL THEN 1
		WHEN SC.SiteID = @SiteID THEN 1
		ELSE 0 
	 END) = 1 AND
	C.Active = 1 AND
	1 = (CASE 
			WHEN @RootCat IS NULL THEN 
			(
				CASE WHEN C.ParentID IS NULL THEN 1 ELSE 0 END
			) 
			WHEN @RootCat = C.ParentID THEN 1 
			ELSE 0 
		END)
ORDER BY
	C.CategoryName


IF @MaxPerPage IS NOT NULL SET ROWCOUNT @MaxPerPage

SELECT DISTINCT
	C.CategoryID,
	C.ParentID,
	C.CategoryName,
	C.ImagePath1,
	C.ImagePath2,
	C.[Description],
	C.Active	
FROM
	#Categories C2
	INNER JOIN Categories C ON C.CategoryID = C2.CategoryID
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
WHERE
	C2.DisplayOrder > (@PageIndex * ISNULL(@MaxPerPage, 0))
ORDER BY
	C.CategoryName

--- GET COUNT
SELECT
	COUNT(1) AS TotalRecords
FROM
	#Categories

DROP TABLE 	#Categories
GO
/****** Object:  Table [dbo].[Sites]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Sites](
	[SiteID] [int] IDENTITY(1,1) NOT NULL,
	[SiteCode] [varchar](5) NOT NULL,
	[SiteName] [varchar](50) NOT NULL,
	[SiteURL] [varchar](200) NOT NULL,
	[Active] [smallint] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Sites] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[ProperCase]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[ProperCase](@Text as varchar(8000))
returns varchar(8000)
as
begin
   declare @Reset bit;
   declare @Ret varchar(8000);
   declare @i int;
   declare @c char(1);

   select @Reset = 1, @i=1, @Ret = '';
   
   while (@i <= len(@Text))
   	select @c= substring(@Text,@i,1),
               @Ret = @Ret + case when @Reset=1 then UPPER(@c) else LOWER(@c) end,
               @Reset = case when @c like '[a-zA-Z]' then 0 else 1 end,
               @i = @i +1
   return @Ret
end
GO
/****** Object:  Table [dbo].[States]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[States](
	[StateID] [int] IDENTITY(1,1) NOT NULL,
	[StateCode] [varchar](2) NOT NULL,
	[StateName] [varchar](50) NOT NULL,
	[SalesTax] [decimal](18, 4) NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_States] PRIMARY KEY CLUSTERED 
(
	[StateID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_Products_Delete]
	@ProductID	Integer
AS

-- Mark the record as deleted
UPDATE 
	Products 
SET
	Active = -1
WHERE
	ProductID = @ProductID
GO
/****** Object:  Table [dbo].[Orders]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Orders](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[SiteID] [int] NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[Address1] [varchar](100) NOT NULL,
	[Address2] [varchar](100) NULL,
	[City] [varchar](50) NOT NULL,
	[State] [varchar](2) NULL,
	[PostalCode] [varchar](50) NOT NULL,
	[Country] [varchar](50) NOT NULL,
	[Phone] [varchar](25) NULL,
	[ShipFirstName] [varchar](50) NOT NULL,
	[ShipLastName] [varchar](50) NOT NULL,
	[ShipAddress1] [varchar](100) NOT NULL,
	[ShipAddress2] [varchar](100) NULL,
	[ShipCity] [varchar](50) NOT NULL,
	[ShipState] [varchar](2) NULL,
	[ShipPostalCode] [varchar](50) NOT NULL,
	[ShipCountry] [varchar](50) NOT NULL,
	[ShipPhone] [varchar](25) NULL,
	[Email] [varchar](100) NULL,
	[Notes] [text] NULL,
	[PaymentMethod] [varchar](20) NOT NULL,
	[CardType] [varchar](20) NULL,
	[CardNumber] [varchar](20) NULL,
	[CardSecurity] [varchar](10) NULL,
	[CardExpiration] [datetime] NULL,
	[CardholderName] [varchar](100) NULL,
	[CardAuthCode] [varchar](20) NULL,
	[CardAuthTransID] [varchar](20) NULL,
	[CheckNumber] [int] NULL,
	[CheckSignatory] [varchar](100) NULL,
	[ShipCost] [money] NOT NULL,
	[ShipTracking] [varchar](50) NULL,
	[SalesTax] [money] NOT NULL,
	[SalesTaxPercent] [decimal](18, 4) NULL,
	[CouponID] [int] NULL,
	[CouponAmount] [money] NULL,
	[CouponPercentage] [decimal](18, 4) NULL,
	[CouponDiscount] [money] NOT NULL,
	[SubTotal] [money] NOT NULL,
	[GrandTotal] [money] NOT NULL,
	[Status] [varchar](20) NOT NULL,
	[StatusDate] [datetime] NOT NULL,
	[FirstShipDate] [datetime] NULL,
	[LastShipDate] [datetime] NULL,
	[PaidDate] [datetime] NULL,
	[VoidDate] [datetime] NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SiteCategories]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SiteCategories](
	[SiteCategoryID] [int] IDENTITY(1,1) NOT NULL,
	[SiteID] [int] NOT NULL,
	[CategoryID] [int] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SiteCategories] PRIMARY KEY CLUSTERED 
(
	[SiteCategoryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Products]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Products](
	[ProductID] [int] IDENTITY(1,1) NOT NULL,
	[CategoryID] [int] NOT NULL,
	[ProductCode] [varchar](50) NOT NULL,
	[ProductName] [varchar](100) NOT NULL,
	[Description] [varchar](6000) NULL,
	[Keywords] [varchar](200) NULL,
	[ImagePath1] [varchar](200) NULL,
	[ImagePath2] [varchar](200) NULL,
	[ImagePath3] [varchar](200) NULL,
	[ImagePath4] [varchar](200) NULL,
	[ImagePath5] [varchar](200) NULL,
	[ImagePath6] [varchar](200) NULL,
	[ImagePath7] [varchar](200) NULL,
	[ImagePath8] [varchar](200) NULL,
	[ImagePath9] [varchar](200) NULL,
	[ImagePath10] [varchar](200) NULL,
	[Cost] [money] NOT NULL,
	[RetailPrice] [money] NOT NULL,
	[OriginalPrice] [money] NOT NULL,
	[Weight] [decimal](18, 4) NOT NULL,
	[Inventory] [int] NULL,
	[ShowNew] [smallint] NOT NULL,
	[ShowReducedPrice] [smallint] NOT NULL,
	[AllowBackorder] [smallint] NOT NULL,
	[Active] [smallint] NOT NULL,
	[System] [smallint] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
	[Length] [varchar](50) NULL,
	[Ring] [varchar](50) NULL,
	[AmountPerBox] [int] NULL,
	[Wrapper] [varchar](50) NULL,
	[OldCategoryID] [int] NULL,
	[ShowFeatured] [smallint] NULL,
	[ShowHomePage] [smallint] NULL,
	[FeaturedTitle] [varchar](255) NULL,
	[FeaturedSubTitle] [varchar](255) NULL,
	[FeaturedBullet1] [varchar](255) NULL,
	[FeaturedBullet2] [varchar](255) NULL,
	[FeaturedBullet3] [varchar](255) NULL,
 CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[OrderItems]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[OrderItems](
	[OrderItemID] [int] IDENTITY(1,1) NOT NULL,
	[OrderID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[ProductCode] [varchar](50) NOT NULL,
	[ProductName] [varchar](100) NOT NULL,
	[Cost] [money] NOT NULL,
	[RetailPrice] [money] NOT NULL,
	[OriginalPrice] [money] NOT NULL,
	[Weight] [decimal](18, 4) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Total] [money] NOT NULL,
	[ShipDate] [datetime] NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_OrderItems] PRIMARY KEY CLUSTERED 
(
	[OrderItemID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[OrderMemos]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderMemos](
	[OrderMemoID] [int] IDENTITY(1,1) NOT NULL,
	[OrderID] [int] NOT NULL,
	[Memo] [text] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_OrderMemos] PRIMARY KEY CLUSTERED 
(
	[OrderMemoID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OrderItemOptions]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[OrderItemOptions](
	[OrderItemOptionID] [int] IDENTITY(1,1) NOT NULL,
	[OrderItemID] [int] NOT NULL,
	[ProductOptionID] [int] NOT NULL,
	[ProductOptionValueID] [int] NOT NULL,
	[OptionName] [varchar](50) NOT NULL,
	[ValueName] [varchar](50) NOT NULL,
	[SKU] [varchar](50) NULL,
	[PriceDifference] [money] NOT NULL,
	[WeightDifference] [decimal](18, 4) NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_OrderItemOptions] PRIMARY KEY CLUSTERED 
(
	[OrderItemOptionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProductOptionValues]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProductOptionValues](
	[ProductOptionValueID] [int] IDENTITY(1,1) NOT NULL,
	[ProductOptionID] [int] NOT NULL,
	[ValueName] [varchar](50) NOT NULL,
	[SKU] [varchar](50) NULL,
	[PriceDifference] [money] NOT NULL,
	[WeightDifference] [decimal](18, 4) NOT NULL,
	[Active] [smallint] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ProductOptionValues] PRIMARY KEY CLUSTERED 
(
	[ProductOptionValueID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProductOptions]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProductOptions](
	[ProductOptionID] [int] IDENTITY(1,1) NOT NULL,
	[ProductID] [int] NOT NULL,
	[OptionName] [varchar](50) NOT NULL,
	[Required] [smallint] NOT NULL,
	[AllowSKU] [smallint] NOT NULL,
	[Active] [smallint] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ProductOptions] PRIMARY KEY CLUSTERED 
(
	[ProductOptionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SiteProducts]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SiteProducts](
	[SiteProductID] [int] IDENTITY(1,1) NOT NULL,
	[SiteID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SiteProducts] PRIMARY KEY CLUSTERED 
(
	[SiteProductID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_Orders_ListByKey]
	@OrderID       Integer
AS

SELECT
	O.OrderID,
	S.SiteID,
	S.SiteName,
	S.SiteCode,
	O.FirstName,
	O.LastName,
	O.Address1,
	O.Address2,
	O.City,
	O.State,
	O.PostalCode,
	O.Country,
	O.ShipFirstName,
	O.ShipLastName,
	O.ShipAddress1,
	O.ShipAddress2,
	O.ShipCity,
	O.ShipState,
	O.ShipPostalCode,
	O.ShipCountry,
	O.Phone,
	O.Email,
	O.Notes,
	O.PaymentMethod,
	O.CardType,
	O.CardNumber,
	O.CardSecurity,
	O.CardExpiration,
	O.CardholderName,
	O.CardAuthCode,
	O.CardAuthTransID,
	O.CheckNumber,
	O.CheckSignatory,
	O.ShipCost,
	O.ShipTracking,
	O.SalesTax,
	O.SalesTaxPercent,
	C.CouponID,
	C.CouponCode,
	C.CouponName,
	O.CouponAmount,
	O.CouponPercentage,
	O.CouponDiscount,
	O.SubTotal,
	O.GrandTotal,
	O.Status,
	O.StatusDate,
	O.FirstShipDate,
	O.LastShipDate,
	O.PaidDate,
	O.VoidDate,
	O.CreateDate, 
	O.ModifyDate
FROM
	Orders O
	INNER JOIN Sites S ON O.SiteID = S.SiteID
	LEFT OUTER JOIN Coupons C ON O.CouponID = C.CouponID
WHERE
	O.OrderID = @OrderID
GO
/****** Object:  StoredProcedure [dbo].[sp_Coupons_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Coupons_Delete]
	@CouponID	Integer
AS

-- Mark the record as deleted
UPDATE 
	Coupons 
SET
	Active = -1
WHERE
	CouponID = @CouponID
GO
/****** Object:  StoredProcedure [dbo].[sp_Coupons_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Coupons_Update]
	@CouponID	Integer,
	@CouponCode	Varchar(50),
	@CouponName	Varchar(50),
	@Description	Varchar(6000),
	@Percentage	Decimal(18, 4),
	@Amount		Money,
	@ExpirationDate	Datetime,
	@Active		Smallint,
	@RetVal		Integer Output
AS

-- Make sure the update does not make it a duplicate
IF EXISTS(SELECT CouponID FROM Coupons WHERE CouponCode = @CouponCode AND CouponID <> @CouponID AND Active > -1)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END

UPDATE
	Coupons
SET
	CouponCode = @CouponCode,
	CouponName = @CouponName,
	[Description] = @Description,
	Percentage = @Percentage,
	Amount = @Amount,
	ExpirationDate = @ExpirationDate,
	Active = @Active,
	ModifyDate = GetDate()
WHERE
	CouponID = @CouponID

-- Return a success indicator
SET @RetVal = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_Coupons_ListByCode]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Coupons_ListByCode]
	@CouponCode	Varchar(50),
	@Active		Smallint = NULL
AS

SELECT
	C.CouponID,
	C.CouponCode,
	C.CouponName,
	C.[Description],
	C.Percentage,
	C.Amount,
	C.ExpirationDate,
	C.Active,
	C.CreateDate,
	C.ModifyDate
FROM
	Coupons C
WHERE
	C.CouponCode = @CouponCode AND
	Active = (CASE WHEN @Active IS NULL THEN Active ELSE @Active END)
GO
/****** Object:  StoredProcedure [dbo].[sp_Coupons_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Coupons_Add]
	@CouponCode	Varchar(50),
	@CouponName	Varchar(50),
	@Description	Varchar(6000),
	@Percentage	Decimal(18, 4),
	@Amount		Money,
	@ExpirationDate	Datetime,
	@Active		Smallint,
	@RetVal		Integer Output
AS

-- Make sure this is not a duplicate record
IF EXISTS(SELECT CouponID FROM Coupons WHERE CouponCode = @CouponCode AND Active > -1)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
	
INSERT INTO Coupons
	(
	CouponCode,
	CouponName, 
	[Description],
	Percentage,
	Amount,
	ExpirationDate,
	Active,
	CreateDate, 
	ModifyDate
	)
	VALUES
	(
	@CouponCode,
	@CouponName, 
	@Description,
	@Percentage,
	@Amount,
	@ExpirationDate,
	@Active,
	GetDate(), 
	GetDate()
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_Coupons_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Coupons_ListByKey]
	@CouponID       Integer
AS

SELECT
	C.CouponID,
	C.CouponCode,
	C.CouponName,
	C.[Description],
	C.Percentage,
	C.Amount,
	C.ExpirationDate,
	C.Active,
	C.CreateDate,
	C.ModifyDate
FROM
	Coupons C	
WHERE
	C.CouponID = @CouponID
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_ListRandom]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_ListRandom]
	@SiteID		Integer,
	@MaxPerPage	Integer,
	@SoldOut	Smallint = 0,
	@Active		Smallint = 1,
	@System		Smallint = 0
AS

SET ROWCOUNT @MaxPerPage
SELECT
	P.ProductID,
	C.CategoryID,
	C.CategoryName,
	PC.CategoryID AS ParentCategoryID,
	PC.CategoryName AS ParentCategoryName,
	P.ProductCode,
	P.ProductName,
	P.ImagePath1,
	P.Cost,
	P.RetailPrice,
	P.OriginalPrice,
	P.Inventory,
	P.ShowNew,
	P.ShowReducedPrice,
	P.System,
	P.Active,
	(CASE WHEN ISNULL(OP.OptionCount, 0) > 0 THEN 1 ELSE 0 END) AS HasOptions	
FROM
	Products P
	INNER JOIN SiteProducts SP ON P.ProductID = SP.ProductID
	INNER JOIN Categories C ON P.CategoryID = C.CategoryID
	LEFT OUTER JOIN Categories PC ON C.ParentID = PC.CategoryID
	LEFT OUTER JOIN
		(SELECT
			ProductID,
			COUNT(1) AS OptionCount
		 FROM
			ProductOptions
		 GROUP BY
			ProductID) AS OP ON P.ProductiD = OP.ProductID
WHERE
	SP.SiteID = (CASE WHEN @SiteID IS NULL THEN SP.SiteID ELSE @SiteID END) AND	
	P.ImagePath1 IS NOT NULL AND
	(CASE	WHEN @SoldOut IS NULL THEN 1
		WHEN @SoldOut = 0 AND ISNULL(P.Inventory, 1) > 0 THEN 1
		WHEN @SoldOut = 0 AND ISNULL(P.Inventory, 1) <= 0 AND P.AllowBackorder = 1 THEN 1
		WHEN @SoldOut = 1 AND ISNULL(P.Inventory, 1) <= 0 AND P.AllowBackorder <> 1 THEN 1		
	 END) = 1 AND
	P.System = (CASE WHEN @System IS NULL THEN P.System ELSE @System END) AND
	P.Active = (CASE WHEN @Active IS NULL THEN P.Active ELSE @Active END) AND
	P.Active > -1 AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1 AND
	ISNULL(PC.Active, 0) = (CASE WHEN @Active IS NULL THEN ISNULL(PC.Active, 0) ELSE @Active END) AND
	ISNULL(PC.Active, 0) > -1
ORDER BY
	NewID()
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_ListByKey]
	@ProductID	Integer
AS
	
SELECT
	P.ProductID,
	PC.CategoryID AS ParentCategoryID,
	PC.CategoryName AS ParentCategoryName,
	C.CategoryID,
	C.CategoryName,
	(CASE	WHEN PC.CategoryID IS NULL THEN C.CategoryName
		WHEN PC.CategoryID IS NOT NULL THEN PC.CategoryName + ' > ' + C.CategoryName
	 END) AS CategoryNameFull,
	P.ProductCode,
	P.ProductName,
	P.Length,
	P.Ring,
	P.AmountPerBox,
	P.Wrapper,
	P.[Description],
	P.Keywords,
	P.ImagePath1,
	P.ImagePath2,
	P.ImagePath3,
	P.ImagePath4,
	P.ImagePath5,
	P.ImagePath6,
	P.ImagePath7,
	P.ImagePath8,
	P.ImagePath9,
	P.ImagePath10,
	P.Cost,
	P.RetailPrice,
	P.OriginalPrice,
	P.Weight,
	P.Inventory,
	P.ShowNew,
	P.ShowReducedPrice,
	P.AllowBackorder,
	P.System,
	P.Active,
	P.CreateDate,
	P.ModifyDate,
	P.ShowFeatured,
	P.ShowHomePage,

	P.FeaturedTitle,
	P.FeaturedSubTitle,
	P.FeaturedBullet1,
	P.FeaturedBullet2,
	P.FeaturedBullet3,
	P.OldCategoryID

FROM
	Products P
	INNER JOIN Categories C ON P.CategoryID = C.CategoryID
	LEFT OUTER JOIN Categories PC ON C.ParentID = PC.CategoryID
WHERE
	P.ProductID = @ProductID
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_ListByCode]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_ListByCode]
	@ProductCode	Varchar(50)
AS
	
SELECT
	P.ProductID,
	PC.CategoryID AS ParentCategoryID,
	PC.CategoryName AS ParentCategoryName,
	C.CategoryID,
	C.CategoryName,
	(CASE	WHEN PC.CategoryID IS NULL THEN C.CategoryName
		WHEN PC.CategoryID IS NOT NULL THEN PC.CategoryName + ' > ' + C.CategoryName
	 END) AS CategoryNameFull,
	P.ProductCode,
	P.ProductName,
	P.[Description],
	P.Keywords,
	P.ImagePath1,
	P.ImagePath2,
	P.ImagePath3,
	P.ImagePath4,
	P.ImagePath5,
	P.ImagePath6,
	P.ImagePath7,
	P.ImagePath8,
	P.ImagePath9,
	P.ImagePath10,
	P.Cost,
	P.RetailPrice,
	P.OriginalPrice,
	P.Weight,
	P.Inventory,
	P.ShowNew,
	P.ShowReducedPrice,
	P.AllowBackorder,
	P.System,
	P.Active,
	P.CreateDate,
	P.ModifyDate,
	P.ShowHomePage,

	P.FeaturedTitle,
	P.FeaturedSubTitle,
	P.FeaturedBullet1,
	P.FeaturedBullet2,
	P.FeaturedBullet3,
	P.OldCategoryID

FROM
	Products P
	INNER JOIN Categories C ON P.CategoryID = C.CategoryID
	LEFT OUTER JOIN Categories PC ON C.ParentID = PC.CategoryID
WHERE
	P.ProductCode = @ProductCode
ORDER BY
	P.ProductName
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_ListTree]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_ListTree]
	@SiteID		Integer = NULL,
	@Active		Smallint = NULL,
	@Indent		Smallint = 10,
	@IndentStr	Varchar(50)
AS

SELECT
	C.CategoryID,
	C.OldParentID,
	C.CategoryName AS FullName,
	C.CategoryName AS IndentedName,
	C.Active
FROM
	Categories C
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
WHERE
	ISNULL(SC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(SC.SiteID, 0) ELSE @SiteID END) AND
	C.ParentID IS NULL AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1
GROUP BY
	C.CategoryID,
	C.OldParentID,
	C.CategoryName,
	C.Active

UNION

SELECT
	C.CategoryID,
	C.OldParentID,
	PC.CategoryName + ' -> ' + C.CategoryName AS FullName,
	REPLICATE(@IndentStr, @Indent) + C.CategoryName AS IndentedName,
	C.Active	
FROM
	Categories C	
	INNER JOIN Categories PC ON C.ParentID = PC.CategoryID	
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
	LEFT OUTER JOIN SiteCategories PSC ON PC.CategoryID = PSC.CategoryID
WHERE
	ISNULL(SC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(SC.SiteID, 0) ELSE @SiteID END) AND
	ISNULL(PSC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(PSC.SiteID, 0) ELSE @SiteID END) AND
	C.ParentID IS NOT NULL AND
	PC.ParentID IS NULL AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1
GROUP BY
	C.CategoryID,
	C.OldParentID,
	PC.CategoryName + ' -> ' + C.CategoryName,
	REPLICATE(@IndentStr, @Indent) + C.CategoryName,
	C.Active
	
UNION

SELECT
	C.CategoryID,
	C.OldParentID,
	PPC.CategoryName + ' -> ' + PC.CategoryName + ' -> ' + C.CategoryName AS FullName,
	REPLICATE(@IndentStr, @Indent) + REPLICATE(@IndentStr, @Indent) + C.CategoryName AS IndentedName,
	C.Active	
FROM
	Categories C	
	INNER JOIN Categories PC ON C.ParentID = PC.CategoryID	
	LEFT JOIN Categories PPC ON PC.ParentID = PPC.CategoryID
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
	LEFT OUTER JOIN SiteCategories PSC ON PC.CategoryID = PSC.CategoryID
WHERE
	ISNULL(SC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(SC.SiteID, 0) ELSE @SiteID END) AND
	ISNULL(PSC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(PSC.SiteID, 0) ELSE @SiteID END) AND
	C.ParentID IS NOT NULL AND
	PC.ParentID IS NOT NULL AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1
GROUP BY
	C.CategoryID,
	C.OldParentID,
	PPC.CategoryName + ' -> ' + PC.CategoryName + ' -> ' + C.CategoryName,
	REPLICATE(@IndentStr, @Indent) + REPLICATE(@IndentStr, @Indent) + C.CategoryName,
	C.Active

ORDER BY
	FullName
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_ListSub]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_ListSub]
	@ParentID		Integer = NULL,
	@SiteID		Integer = NULL,
	@Active		Smallint = NULL,
	@RootCat		Integer = NULL
AS

SELECT DISTINCT
	C.CategoryID,
	C.ParentID,
	C.CategoryName,
	C.[Description],
	C.Active	
FROM
	Categories C
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
WHERE
	ISNULL(C.ParentID, 0) = (CASE WHEN @ParentID IS NULL THEN ISNULL(C.ParentID, 0) ELSE @ParentID END) AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1 AND
	(CASE	WHEN @SiteID IS NULL THEN 1
		WHEN SC.SiteID = @SiteID THEN 1
		ELSE 0 
	 END) = 1
	And C.ParentID = @RootCat	
ORDER BY
	C.CategoryName
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_Update]
	@CategoryID	Integer,
	@ParentID	Integer,
	@CategoryName	Varchar(50),
	@Description	Varchar(6000),
	@Active		Smallint,
	@Sort		INTEGER=NULL,
	@RetVal		Integer Output
AS

-- Make sure the update does not make it a duplicate
IF @ParentID IS NULL
	BEGIN
	IF EXISTS(SELECT CategoryID FROM Categories WHERE ParentID IS NULL AND CategoryName = @CategoryName AND CategoryID <> @CategoryID AND Active > -1)
		BEGIN
		SET @RetVal = -1  -- Indicate duplicate found
		RETURN
		END
	END
ELSE
	BEGIN
	IF EXISTS(SELECT CategoryID FROM Categories WHERE ParentID = @ParentID AND CategoryName = @CategoryName AND CategoryID <> @CategoryID AND Active > -1)
		BEGIN
		SET @RetVal = -1  -- Indicate duplicate found
		RETURN
		END
	END

UPDATE
	Categories
SET
	ParentID = @ParentID,
	CategoryName = @CategoryName,
	[Description] = @Description,
	Active = @Active,
	ModifyDate = GetDate(),
	OldParentID = @Sort
WHERE
	CategoryID = @CategoryID

-- Return a success indicator
SET @RetVal = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_ListByKey]
	@CategoryID       Integer
AS

SELECT
	C.CategoryID,
	C.ParentID,
	PC.CategoryName AS ParentCategoryName,
	C.CategoryName,
	(CASE	WHEN PC.CategoryName IS NULL THEN C.CategoryName
		ELSE PC.CategoryName + ' -> ' + C.CategoryName 
	 END) AS CategoryNameFull,	
	C.[Description],
	C.Active,
	C.ImagePath1,
	C.ImagePath2,
	C.ImagePath1Hip,
	C.ImagePath2Hip,
	C.CreateDate,
	C.ModifyDate,
	C.OldParentID
FROM
	Categories C
	LEFT OUTER JOIN Categories PC ON C.ParentID = PC.CategoryID
WHERE
	C.CategoryID = @CategoryID
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_SetImages]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_SetImages]

	@CategoryID	Integer,
	@ImagePath1	Varchar(200),
	@ImagePath2	Varchar(200),
	@ImagePath1Hip Varchar(200),
	@ImagePath2Hip Varchar(200)

AS

UPDATE
	Categories
SET
	ImagePath1 = @ImagePath1,
	ImagePath2 = @ImagePath2,
	ImagePath1Hip = @ImagePath1Hip,
	ImagePath2Hip = @ImagePath2Hip,
	ModifyDate = GetDate()
WHERE
	CategoryID = @CategoryID
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_Delete]
	@CategoryID	Integer
AS

-- Mark the record as deleted
UPDATE 
	Categories 
SET
	Active = -1
WHERE
	CategoryID = @CategoryID
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_Add]
	@ParentID	Integer,
	@CategoryName	Varchar(50),
	@Description	Varchar(6000),
	@Active		Smallint,
	@Sort		INTEGER=NULL,
	@RetVal		Integer Output
AS

-- Make sure this is not a duplicate record
IF @ParentID IS NULL
	BEGIN
	IF EXISTS(SELECT CategoryID FROM Categories WHERE ParentID IS NULL AND CategoryName = @CategoryName AND Active > -1)
		BEGIN
		SET @RetVal = -1  -- Indicate duplicate found
		RETURN
		END
	END
ELSE
	BEGIN
	IF EXISTS(SELECT CategoryID FROM Categories WHERE ParentID = @ParentID AND CategoryName = @CategoryName AND Active > -1)
		BEGIN
		SET @RetVal = -1  -- Indicate duplicate found
		RETURN
		END
	END
	
INSERT INTO Categories
	(
	ParentID, 
	CategoryName, 
	[Description],
	Active,
	CreateDate, 
	ModifyDate,
	OldParentID
	)
	VALUES
	(
	@ParentID, 
	@CategoryName, 
	@Description,
	@Active,
	GetDate(), 
	GetDate(),
	@Sort
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_ListOutline]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_ListOutline]
	@SiteID		Integer = NULL,
	@Active		Smallint = NULL
AS

SELECT
	C.CategoryID,
	C.CategoryName AS FullName,
	C.CategoryName AS CombinedName,
	C.Description,
	C.Active
FROM
	Categories C
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
WHERE
	ISNULL(SC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(SC.SiteID, 0) ELSE @SiteID END) AND
	C.ParentID IS NULL AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1
GROUP BY
	C.CategoryID,
	C.CategoryName,
	C.Description,
	C.Active

UNION

SELECT
	C.CategoryID,
	'    - ' + C.CategoryName AS FullName,
	PC.CategoryName + ' -> ' + C.CategoryName AS CombinedName,
	C.Description,
	C.Active	
FROM
	Categories C	
	INNER JOIN Categories PC ON C.ParentID = PC.CategoryID	
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
	LEFT OUTER JOIN SiteCategories PSC ON PC.CategoryID = PSC.CategoryID
WHERE
	ISNULL(SC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(SC.SiteID, 0) ELSE @SiteID END) AND
	ISNULL(PSC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(PSC.SiteID, 0) ELSE @SiteID END) AND
	C.ParentID IS NOT NULL AND
	PC.ParentID IS NULL AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1
GROUP BY
	C.CategoryID,
	PC.CategoryName,
	C.CategoryName,
	C.Description,
	C.Active

UNION

SELECT
	C.CategoryID,
	'    - ' + PC.CategoryName + '    - ' + C.CategoryName AS FullName,
	PPC.CategoryName + ' -> ' + PC.CategoryName + ' -> ' + C.CategoryName AS CombinedName,
	C.Description,
	C.Active	
FROM
	Categories C	
	INNER JOIN Categories PC ON C.ParentID = PC.CategoryID	
	LEFT JOIN Categories PPC ON PC.ParentID = PPC.CategoryID
	LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
	LEFT OUTER JOIN SiteCategories PSC ON PC.CategoryID = PSC.CategoryID
WHERE
	ISNULL(SC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(SC.SiteID, 0) ELSE @SiteID END) AND
	ISNULL(PSC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(PSC.SiteID, 0) ELSE @SiteID END) AND
	C.ParentID IS NOT NULL AND
	PC.ParentID IS NOT NULL AND
	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
	C.Active > -1
GROUP BY
	C.CategoryID,
	PPC.CategoryName,
	PC.CategoryName,
	C.CategoryName,
	C.Description,
	C.Active
	
ORDER BY
	CombinedName
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_List]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_List]
	@ParentID	Integer = NULL,
	@SiteID		Integer = NULL,
	@Active		Smallint = NULL,
	@CustomSort	SMALLINT = NULL
AS

/* CTE for Distinct Outer join with Site Cats */
WITH Distinct_Categories (CategoryID, ParentID, CategoryName, [Description], Active, ImagePath1, ImagePath2, OldParentID)
AS
(
	SELECT DISTINCT
		C.CategoryID,
		C.ParentID,
		C.CategoryName,
		C.[Description],
		C.Active,	
		C.ImagePath1,
		C.ImagePath2,
		C.OldParentID
	FROM
		Categories C
		LEFT OUTER JOIN SiteCategories SC ON (C.CategoryID = SC.CategoryID)
	WHERE
		ISNULL(C.ParentID, 0) = (CASE WHEN @ParentID IS NULL THEN ISNULL(C.ParentID, 0) ELSE @ParentID END) 
	AND	C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) 
	AND	C.Active > -1 
	AND	(CASE	WHEN @SiteID IS NULL THEN 1
			WHEN SC.SiteID = @SiteID THEN 1
			ELSE 0 
		 END) = 1
)

/* Lets get info from our CTE and sort it based on input params */
SELECT
	DC.CategoryID, 
	DC.ParentID, 
	DC.CategoryName, 
	DC.[Description], 
	DC.Active, 
	DC.ImagePath1, 
	DC.ImagePath2, 
	DC.OldParentID
FROM
	Distinct_Categories DC
ORDER BY
	(CASE
		WHEN @CustomSort = 1 THEN DC.OldParentID
	 END) ASC,
	(CASE
		WHEN @CustomSort IS NULL THEN DC.CategoryName
	 END) ASC
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_ListByKeyList]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_ListByKeyList]
	@ProductIDs	Varchar(8000)
AS
	
SELECT
	P.ProductID,
	PC.CategoryID AS ParentCategoryID,
	PC.CategoryName AS ParentCategoryName,
	C.CategoryID,
	C.CategoryName,
	(CASE	WHEN PC.CategoryID IS NULL THEN C.CategoryName
		WHEN PC.CategoryID IS NOT NULL THEN PC.CategoryName + ' > ' + C.CategoryName
	 END) AS CategoryNameFull,
	P.ProductCode,
	P.ProductName,
	P.[Description],
	P.Keywords,
	P.ImagePath1,
	P.ImagePath2,
	P.ImagePath3,
	P.ImagePath4,
	P.ImagePath5,
	P.Cost,
	P.RetailPrice,
	P.OriginalPrice,
	P.Weight,
	P.Inventory,
	P.ShowNew,
	P.ShowReducedPrice,
	P.AllowBackorder,
	P.System,
	P.Active,
	P.CreateDate,
	P.ModifyDate
FROM
	Products P
	INNER JOIN dbo.ConvertIntListToTable(@ProductIDs) PL ON P.ProductID = PL.Value
	INNER JOIN Categories C ON P.CategoryID = C.CategoryID
	LEFT OUTER JOIN Categories PC ON C.ParentID = PC.CategoryID
GO
/****** Object:  StoredProcedure [dbo].[sp_Categories_ListBreadCrumbs]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Categories_ListBreadCrumbs]	
	@SiteID		Integer = NULL,
	@Active		Smallint = NULL
AS
-- pre-filter the list of categories to include in this outline using a common 
-- table expression. We also aggregate the count of sub categories for each.
;WITH CategoriesFiltered AS
(
	SELECT
		C.ParentID,
		C.OldParentID,
		C.CategoryID,		
		C.CategoryName,
		C.Active,
		ISNULL(CC.ChildCount, 0) SubCategoriesCount		
	FROM
		Categories C
		LEFT OUTER JOIN SiteCategories SC ON C.CategoryID = SC.CategoryID
		-- count how many sub-categories are in each category
		LEFT OUTER JOIN 
		(
			SELECT
				ParentID,
				COUNT(1) ChildCount
			FROM
				Categories
			GROUP BY
				ParentID
		) AS CC ON C.CategoryID = CC.ParentID
	WHERE
		ISNULL(SC.SiteID, 0) = (CASE WHEN @SiteID IS NULL THEN ISNULL(SC.SiteID, 0) ELSE @SiteID END) AND
		C.Active = (CASE WHEN @Active IS NULL THEN C.Active ELSE @Active END) AND
		C.Active > -1
),

-- generate the outline using a recursive common table expression named "Outline". The first query pulls 
-- the anchor records (top level categories) and the second query references itself (INNER JOIN Outline)
-- and recursively builds the outline for as many records deep as it finds matches for. This will produce 
-- a list of categories that can be infinitely deep and allows you to use concatenation on previous results.
Outline AS 
(
	SELECT
		-1 AS ParentCategory,
		C.CategoryID,
		C.CategoryName,
		CONVERT(VARCHAR(MAX), C.CategoryID) AS CategoryIDCombined,
		CONVERT(Varchar(MAX), C.CategoryName) AS FullName,
		CONVERT(Varchar(MAX), C.CategoryName) AS CombinedName,		
		C.Active,
		1 AS [LEVEL],
		C.OldParentID AS SortID,
		C.SubCategoriesCount	
	FROM
		CategoriesFiltered C
	WHERE
		C.ParentID IS NULL --OR C.CategoryID = @CategoryID
		--C.CategoryID = @CategoryID	
	UNION ALL

	SELECT
		PC.CategoryID AS ParentCategory,
		C.CategoryID,
		C.CategoryName,
		PC.CategoryIDCombined + ',' + CONVERT(VARCHAR(MAX), C.CategoryID) CategoryIDCombined, 
		(CASE WHEN PC.Level > 1 THEN PC.FullName ELSE '' END) + '    - ' + C.CategoryName AS FullName,
		PC.CombinedName + ', ' + C.CategoryName AS CombinedName,		
		C.Active,
		PC.Level + 1 AS [LEVEL],
		C.OldParentID AS SortID,
		C.SubCategoriesCount	
	FROM
		CategoriesFiltered C	
		INNER JOIN Outline PC ON C.ParentID = PC.CategoryID	 --< recursive join
)
-- de-dupe all the categories and sort them
SELECT DISTINCT CategoryID, CategoryIDCombined, [Level], CombinedName FROM Outline ORDER BY CombinedName
GO
/****** Object:  StoredProcedure [dbo].[sp_NewsletterSubscription_Save]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_NewsletterSubscription_Save] 
	-- Add the parameters for the stored procedure here
	@SiteID INT,
	@Email VARCHAR(255),
	@Name VARCHAR(150) = null,
	@IP VARCHAR(16)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @EmailCheck VARCHAR(255)

	SELECT @EmailCheck = Email
	FROM NewsletterSubscriptions
	WHERE Email = @Email AND SiteID = @SiteID

	-- Raise an error if the email is already in the list
	IF @EmailCheck IS NOT NULL
		RAISERROR('Email already subscribed',16,1);
	
	-- Don't try to insert just return if there was an error
	IF @@ERROR <> 0
		RETURN

    -- Insert statements for procedure here
	INSERT INTO NewsletterSubscriptions
	(
		SiteID,
		Email,
		[Name],
		SignupDate,
		SignupIP
	)
	VALUES 
	(
		@SiteID,
		@Email,
		@Name,
		CURRENT_TIMESTAMP,
		@IP
	)
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Users_Get]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Users_Get]

	@Username VarChar(100)
AS

SELECT
	UserId,
	UserName,
	[Password],
	AccessLevel
FROM
	Users
WHERE
	Username = @UserName
	And Active = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_Users_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Users_Delete]	
	@UserID as Int
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM UserSites WHERE UserID = @UserID

	DELETE FROM Users WHERE UserID = @UserID

END
GO
/****** Object:  StoredProcedure [dbo].[sp_Users_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Users_Add]
	@Username varchar(50),
	@Password varchar(50),
	@AccessLevel int,
	@Active int,
	@RetVal Integer Output
AS
BEGIN
	INSERT INTO Users (
		Username,
		Password,
		AccessLevel,
		Active )
	VALUES (
		@Username,
		@Password,
		@AccessLevel,
		@Active )

	SET @RetVal = @@IDENTITY
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Users_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Users_Update]
	@Username varchar(50),
	@Password varchar(50)=null,
	@AccessLevel int,
	@Active int,
	@UserID int
AS
BEGIN

	UPDATE 
		Users
	SET
		Username=@Username,
		AccessLevel=@AccessLevel,
		Active=@Active
	WHERE
		UserID = @UserID

	-- Only update if we have a password	
	IF @Password IS NOT NULL OR LEN(@Password) > 0
		BEGIN
		UPDATE
			Users
		SET
			Password=@Password
		WHERE
			UserID = @UserID
		END

	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Users_List]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Users_List]
	@Active Int = null
AS

SELECT
	UserId,
	UserName,
	[Password],
	AccessLevel,
	Active
FROM
	Users
WHERE
	Active = (CASE WHEN @Active IS NULL THEN Active ELSE @Active END)
ORDER BY
	UserName
GO
/****** Object:  StoredProcedure [dbo].[sp_Users_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Users_ListByKey]	
	@UserID as Int
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		UserID,
		Username,
		Password,
		AccessLevel,
		Active
	FROM
		Users
	WHERE
		UserID=@UserID
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptions_ListByKeyList]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptions_ListByKeyList]
	@ProductOptionIDs	Varchar(8000)
AS
	
SELECT
	PO.ProductOptionID,
	PO.ProductID,
	PO.OptionName,
	PO.Required,
	PO.AllowSKU,
	PO.Active,
	PO.DisplayOrder,
	PO.CreateDate,
	PO.ModifyDate
FROM
	ProductOptions PO
	INNER JOIN dbo.ConvertIntListToTable(@ProductOptionIDs) ID ON PO.ProductOptionID = ID.Value
ORDER BY
	PO.DisplayOrder
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptionValues_ListByKeyList]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptionValues_ListByKeyList]
	@ProductOptionValueIDs	Varchar(8000)
AS
	
SELECT
	PO.ProductOptionValueID,
	PO.ProductOptionID,
	O.OptionName,
	PO.ValueName,
	PO.SKU,
	PO.PriceDifference,
	PO.WeightDifference,
	PO.Active,
	PO.DisplayOrder,
	PO.CreateDate,
	PO.ModifyDate
FROM
	ProductOptionValues PO
	INNER JOIN dbo.ConvertIntListToTable(@ProductOptionValueIDs) ID ON PO.ProductOptionValueID = ID.Value
	INNER JOIN ProductOptions O ON PO.ProductOptionID = O.ProductOptionID
ORDER BY
	O.DisplayOrder,
	PO.DisplayOrder
GO
/****** Object:  StoredProcedure [dbo].[sp_Settings_SetValue]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Settings_SetValue]
	@SettingType	Varchar(50),
	@SettingValue	Varchar(500)
AS

IF EXISTS(SELECT * FROM Settings WHERE SettingType = @SettingType)
	BEGIN
	UPDATE
		Settings
	SET
		SettingValue = @SettingValue,
		ModifyDate = GetDate()
	WHERE
		SettingType = @SettingType
	END
ELSE
	BEGIN
	INSERT INTO Settings (SettingType, SettingValue) VALUES (@SettingType, @SettingValue)	
	END
GO
/****** Object:  StoredProcedure [dbo].[sp_Settings_ListByType]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Settings_ListByType]
	@SettingType	Varchar(50)
AS

SELECT
	SettingID,
	SettingType,
	SettingValue
FROM
	Settings
WHERE
	SettingType = @SettingType
GO
/****** Object:  StoredProcedure [dbo].[sp_SiteProducts_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_SiteProducts_Add]
	@SiteID		Integer,
	@ProductID	Integer,
	@RetVal		Integer Output
AS

-- Make sure this is not a duplicate record
IF EXISTS(SELECT SiteProductID FROM SiteProducts WHERE SiteID = @SiteID AND ProductID = @ProductID)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
	
INSERT INTO SiteProducts
	(
	SiteID,
	ProductID,
	CreateDate, 
	ModifyDate
	)
	VALUES
	(
	@SiteID,
	@ProductID,
	GetDate(), 
	GetDate()
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_SiteProducts_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_SiteProducts_Delete]
	@SiteID		Integer,
	@ProductID	Integer
AS

DELETE FROM SiteProducts WHERE SiteID = @SiteID AND ProductID = @ProductID
GO
/****** Object:  StoredProcedure [dbo].[sp_SiteProducts_List]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_SiteProducts_List]
	@SiteID		Integer = NULL,
	@ProductID	Integer = NULL
AS

SELECT
	SiteProductID,
	SiteID,	
	ProductID,
	CreateDate,
	ModifyDate
FROM
	SiteProducts
WHERE
	SiteID = (CASE WHEN @SiteID IS NULL THEN SiteID ELSE @SiteID END) AND
	ProductID = (CASE WHEN @ProductID IS NULL THEN ProductID ELSE @ProductID END)
GO
/****** Object:  StoredProcedure [dbo].[sp_Sites_ListSelectedByProduct]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Sites_ListSelectedByProduct]
	@ProductID	Integer,
	@Active		Smallint = NULL
AS

SELECT
	S.SiteID,
	S.SiteCode,
	S.SiteName,
	S.SiteURL,
	S.Active,
	S.CreateDate,
	S.ModifyDate,
	(CASE WHEN SP.SiteProductID IS NULL THEN 0 ELSE 1 END) AS Selected
FROM
	Sites S
	LEFT OUTER JOIN SiteProducts SP ON 
		S.SiteID = SP.SiteID AND
		@ProductID = SP.ProductID
WHERE
	Active = (CASE WHEN @Active IS NULL THEN S.Active ELSE @Active END)
ORDER BY
	S.SiteName
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_PendingShipment]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_Products_PendingShipment] 

AS

Select 
OI.ProductID, 
OI.ProductCode, 
OI.ProductName,
P.ImagePath1,
Sum(OI.Quantity) as Quantity
From OrderItems OI
Left Join Orders O on O.OrderID = OI.OrderID
Left Join Products P on P.ProductID = OI.ProductID
Where OI.ShipDate is Null
And OI.OrderID > 170000 
And OI.ProductID <> 80 
And OI.ProductID <> 81
And OI.ProductID <> 82
And OI.ProductID <> 89
And (O.Status = 'Pending Shipment'
Or O.Status = 'Backordered')
Group By OI.ProductID, OI.ProductCode, OI.ProductName, P.ImagePath1
Order By OI.ProductID
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_ListStatusCounts]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Orders_ListStatusCounts] AS
	
SELECT
	Status,
	COUNT(1) AS [Count]
FROM
	Orders
GROUP BY
	Status
ORDER BY
	Status
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_SetPaid]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Orders_SetPaid]
	@OrderID	Integer,
	@CheckNumber	Integer,
	@CheckSignatory	Varchar(100),
	@Status		Varchar(20)
AS

-- Mark the record as deleted
UPDATE 
	Orders 
SET
	Status = @Status,
	StatusDate = GetDate(),
	CheckNumber = @CheckNumber,
	CheckSignatory = @CheckSignatory,
	PaidDate = GetDate(),
	ModifyDate = GetDate()
WHERE
	OrderID = @OrderID
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_Orders_Add]
	@SiteID			Integer,
	@FirstName		Varchar(50),
	@LastName		Varchar(50),
	@Address1		Varchar(100),
	@Address2		Varchar(100),
	@City			Varchar(50),
	@State			Varchar(2),
	@PostalCode		Varchar(50),
	@Country		Varchar(50),
	@ShipFirstName		Varchar(50),
	@ShipLastName		Varchar(50),
	@ShipAddress1		Varchar(100),
	@ShipAddress2		Varchar(100),
	@ShipCity		Varchar(50),
	@ShipState		Varchar(2),
	@ShipPostalCode		Varchar(50),
	@ShipCountry		Varchar(50),
	@Phone			Varchar(25),
	@Email			Varchar(100),
	@Notes			Text,
	@PaymentMethod		Varchar(20),
	@CardType		Varchar(20),
	@CardNumber		Varchar(20),
	@CardSecurity		Varchar(10),
	@CardExpiration		Datetime,
	@CardholderName		Varchar(100),
	@CardAuthCode		Varchar(20),
	@CardAuthTransID	Varchar(20),
	@ShipCost		Money,
	@SalesTax		Money,
	@SalesTaxPercent	Decimal(18, 4),
	@CouponID		Integer,
	@CouponAmount		Money,
	@CouponPercentage	Decimal(18, 4),
	@CouponDiscount		Money,
	@SubTotal		Money,
	@GrandTotal		Money,
	@IsPaid			TinyInt = 1,
	@Status			Varchar(20),
	@RetVal			Integer Output
AS

INSERT INTO Orders
	(
	SiteID,
	FirstName,
	LastName,
	Address1,
	Address2,
	City,
	State,
	PostalCode,
	Country,
	ShipFirstName,
	ShipLastName,
	ShipAddress1,
	ShipAddress2,
	ShipCity,
	ShipState,
	ShipPostalCode,
	ShipCountry,
	Phone,
	Email,
	Notes,
	PaymentMethod,
	CardType,
	CardNumber,
	CardSecurity,
	CardExpiration,
	CardholderName,
	CardAuthCode,
	CardAuthTransID,
	ShipCost,
	ShipTracking,
	SalesTax,
	SalesTaxPercent,
	CouponID,
	CouponAmount,
	CouponPercentage,
	CouponDiscount,
	SubTotal,
	GrandTotal,
	Status,
	StatusDate,
	FirstShipDate,
	LastShipDate,
	PaidDate,
	VoidDate,
	CreateDate, 
	ModifyDate
	)
	VALUES
	(
	@SiteID,
	@FirstName,
	@LastName,
	@Address1,
	@Address2,
	@City,
	@State,
	@PostalCode,
	@Country,
	@ShipFirstName,
	@ShipLastName,
	@ShipAddress1,
	@ShipAddress2,
	@ShipCity,
	@ShipState,
	@ShipPostalCode,
	@ShipCountry,
	@Phone,
	@Email,
	@Notes,
	@PaymentMethod,
	@CardType,
	@CardNumber,
	@CardSecurity,
	@CardExpiration,
	@CardholderName,
	@CardAuthCode,
	@CardAuthTransID,
	@ShipCost,
	NULL, -- ShipTracking
	@SalesTax,
	@SalesTaxPercent,
	@CouponID,
	@CouponAmount,
	@CouponPercentage,
	@CouponDiscount,
	@SubTotal,
	@GrandTotal,
	@Status,
	GetDate(),
	NULL, -- FirstShipDate
	NULL, -- LastShipDate
	(CASE WHEN @IsPaid = 1 THEN GetDate() ELSE NULL END), -- PaidDate
	NULL, -- VoidDate
	GetDate(), 
	GetDate()
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_SetVoided]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_Orders_SetVoided]
	@OrderID	Integer,
	@Status		Varchar(20)
AS

-- Mark the record as deleted
UPDATE 
	Orders 
SET
	Status = @Status,
	StatusDate = GetDate(),
	VoidDate = GetDate(),
	ModifyDate = GetDate()
WHERE
	OrderID = @OrderID
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_SetStatus]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Orders_SetStatus]
	@OrderID	Integer,
	@Status		Varchar(20)
AS

-- Mark the record as deleted
UPDATE 
	Orders 
SET
	Status = @Status,
	StatusDate = GetDate(),
	ModifyDate = GetDate()
WHERE
	OrderID = @OrderID
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_SetShipped]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_Orders_SetShipped]
	@OrderID	Integer,
	@ShipTracking	Varchar(50),
	@Status		Varchar(20),
	@SetStatusDate	Smallint = 0,
	@SetFirstShip	Smallint = 0,
	@SetLastShip	Smallint = 0
AS

-- Mark the record as deleted
UPDATE 
	Orders 
SET
	Status = @Status,
	StatusDate = (CASE WHEN @SetStatusDate = 1 THEN GetDate() ELSE StatusDate END),
	ShipTracking = @ShipTracking,
	FirstShipDate = (CASE WHEN FirstShipDate IS NULL AND @SetFirstShip = 1 THEN GetDate() ELSE FirstShipDate END),
	LastShipDate = (CASE WHEN LastShipDate IS NULL AND @SetLastShip = 1 THEN GetDate() ELSE LastShipDate END),
	ModifyDate = GetDate()
WHERE
	OrderID = @OrderID
GO
/****** Object:  StoredProcedure [dbo].[sp_Orders_SetAuthInfo]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Orders_SetAuthInfo]
	@OrderID		Integer,
	@CardAuthCode		Varchar(20),
	@CardAuthTransID	Varchar(20)
AS

-- Mark the record as deleted
UPDATE 
	Orders 
SET
	CardAuthCode = @CardAuthCode,
	CardAuthTransID = @CardAuthTransID,
	ModifyDate = GetDate()
WHERE
	OrderID = @OrderID
GO
/****** Object:  StoredProcedure [dbo].[sp_SiteCategories_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_SiteCategories_Delete]
	@SiteID		Integer,
	@CategoryID	Integer
AS

DELETE FROM SiteCategories WHERE SiteID = @SiteID AND CategoryID = @CategoryID
GO
/****** Object:  StoredProcedure [dbo].[sp_SiteCategories_List]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_SiteCategories_List]
	@SiteID		Integer = NULL,
	@CategoryID	Integer = NULL
AS

SELECT
	SiteCategoryID,
	SiteID,	
	CategoryID,
	CreateDate,
	ModifyDate
FROM
	SiteCategories
WHERE
	SiteID = (CASE WHEN @SiteID IS NULL THEN SiteID ELSE @SiteID END) AND
	CategoryID = (CASE WHEN @CategoryID IS NULL THEN CategoryID ELSE @CategoryID END)
GO
/****** Object:  StoredProcedure [dbo].[sp_SiteCategories_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_SiteCategories_Add]
	@SiteID		Integer,
	@CategoryID	Integer,
	@RetVal		Integer Output
AS

-- Make sure this is not a duplicate record
IF EXISTS(SELECT SiteCategoryID FROM SiteCategories WHERE SiteID = @SiteID AND CategoryID = @CategoryID)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
	
INSERT INTO SiteCategories
	(
	SiteID,
	CategoryID,
	CreateDate, 
	ModifyDate
	)
	VALUES
	(
	@SiteID,
	@CategoryID,
	GetDate(), 
	GetDate()
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_Sites_ListSelectedByCategory]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Sites_ListSelectedByCategory]
	@CategoryID	Integer,
	@Active		Smallint = NULL
AS

SELECT
	S.SiteID,
	S.SiteCode,
	S.SiteName,
	S.SiteURL,
	S.Active,
	S.CreateDate,
	S.ModifyDate,
	(CASE WHEN SC.SiteCategoryID IS NULL THEN 0 ELSE 1 END) AS Selected
FROM
	Sites S
	LEFT OUTER JOIN SiteCategories SC ON 
		S.SiteID = SC.SiteID AND
		@CategoryID = SC.CategoryID
WHERE
	Active = (CASE WHEN @Active IS NULL THEN S.Active ELSE @Active END)
ORDER BY
	S.SiteName
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderItemOptions_ListByOrder]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderItemOptions_ListByOrder]
	@OrderID	Integer
AS

SELECT
	O.OrderItemOptionID,
	O.OrderItemID,
	O.ProductOptionID,
	O.ProductOptionValueID,
	O.OptionName,
	O.ValueName,
	O.SKU,
	O.PriceDifference,
	O.WeightDifference,
	O.CreateDate,
	O.ModifyDate
FROM
	OrderItemOptions O
	INNER JOIN OrderItems I ON O.OrderItemID = I.OrderItemID
WHERE
	I.OrderID = @OrderID
ORDER BY
	OrderItemOptionID
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderItems_SetShipped]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderItems_SetShipped]
	@OrderItemID	Integer
AS

UPDATE
	OrderItems
SET
	ShipDate = GetDate(),
	ModifyDate = GetDate()
WHERE
	OrderItemID = @OrderItemID
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderItems_ListByOrder]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderItems_ListByOrder]
	@OrderID       Integer
AS

SELECT
	OI.OrderItemID,
	OI.OrderID,
	OI.ProductID,
	OI.ProductCode,
	OI.ProductName,
	OI.Cost,
	OI.RetailPrice,
	OI.OriginalPrice,
	OI.OriginalPrice - OI.RetailPrice AS Discount,
	OI.Weight,
	OI.Quantity,
	P.Inventory,
	P.ImagePath1,
	P.System,
	OI.Total,
	OI.ShipDate,
	OI.CreateDate, 
	OI.ModifyDate
FROM
	OrderItems OI
	INNER JOIN Products P ON OI.ProductID = P.ProductID
WHERE
	OI.OrderID = @OrderID
ORDER BY
	OI.OrderItemID
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderItems_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderItems_Add]
	@OrderID	Integer,
	@ProductID	Integer,
	@ProductCode	Varchar(50),
	@ProductName	Varchar(100),
	@Cost		Money,
	@RetailPrice	Money,
	@OriginalPrice	Money,
	@Weight		Decimal(18, 4),
	@Quantity	Integer,
	@Total		Money,
	@RetVal		Integer Output
AS
	
INSERT INTO OrderItems
	(
	OrderID,
	ProductID,
	ProductCode,
	ProductName,
	Cost,
	RetailPrice,
	OriginalPrice,
	Weight,
	Quantity,
	Total,
	ShipDate,
	CreateDate, 
	ModifyDate
	)
	VALUES
	(
	@OrderID,
	@ProductID,
	@ProductCode,
	@ProductName,
	@Cost,
	@RetailPrice,
	@OriginalPrice,
	@Weight,
	@Quantity,
	@Total,
	NULL, -- Not shipped yet
	GetDate(), 
	GetDate()
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptions_ListByProduct]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptions_ListByProduct]
	@ProductID	Integer = NULL,
	@Active		Smallint = NULL	
AS

SELECT
	ProductOptionID,
	ProductID,
	OptionName,
	Required,
	AllowSKU,
	Active,
	DisplayOrder,
	CreateDate,
	ModifyDate
FROM
	ProductOptions
WHERE
	ProductID = @ProductID AND
	Active = (CASE WHEN @Active IS NULL THEN Active ELSE @Active END) AND
	Active > -1
ORDER BY
	DisplayOrder
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptions_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptions_Add]
	@ProductID	Integer,
	@OptionName	VarChar(50),
	@Required	SmallInt,
	@AllowSKU	SmallInt,
	@Active		SmallInt,
	@RetVal		Integer Output
AS

IF EXISTS(SELECT * FROM dbo.ProductOptions WHERE ProductID = @ProductID AND OptionName = @OptionName AND Active > -1)
	BEGIN
	SET @RetVal = -1
	RETURN
	END

DECLARE @Order Integer
SET @Order = (SELECT ISNULL(MAX(DisplayOrder), 0) + 1 FROM ProductOptions WHERE ProductID = @ProductID AND Active > -1)

INSERT INTO ProductOptions
	(
	ProductID,
	OptionName,
	Required,
	AllowSKU,
	Active,
	DisplayOrder,
	CreateDate,
	ModifyDate
	)
VALUES
	(
	@ProductID,
	@OptionName,
	@Required,
	@AllowSKU,
	@Active,
	@Order,
	GetDate(),
	GetDate()
	)

SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptions_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptions_ListByKey]
	@ProductOptionID	Integer
AS
	
SELECT
	ProductOptionID,
	ProductID,
	OptionName,
	Required,
	AllowSKU,
	Active,
	DisplayOrder,
	CreateDate,
	ModifyDate
FROM
	ProductOptions
WHERE
	ProductOptionID = @ProductOptionID
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptions_SetOrder]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptions_SetOrder]
	@ProductOptionID	Integer,
	@DisplayOrder		Integer
AS

UPDATE
	ProductOptions
SET
	DisplayOrder = @DisplayOrder,
	ModifyDate = GetDate()
WHERE
	ProductOptionID = @ProductOptionID

-- Return a success indicator
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptionValues_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptionValues_ListByKey]
	@ProductOptionValueID	Integer
AS
	
SELECT
	V.ProductOptionValueID,
	O.ProductOptionID,
	O.OptionName,
	O.AllowSKU,
	O.Required,
	V.ValueName,
	V.SKU,
	V.PriceDifference,
	V.WeightDifference,
	V.Active,
	V.DisplayOrder,
	V.CreateDate,
	V.ModifyDate
FROM
	ProductOptionValues V
	INNER JOIN ProductOptions O ON V.ProductOptionID = O.ProductOptionID
WHERE
	ProductOptionValueID = @ProductOptionValueID
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptions_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptions_Delete]
	@ProductOptionID	Integer
AS

UPDATE 
	dbo.ProductOptionValues
SET
	Active = -1
WHERE 
	ProductOptionID = @ProductOptionID

UPDATE 
	dbo.ProductOptions 
SET
	Active = -1
WHERE 
	ProductOptionID = @ProductOptionID
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptionValues_ListByProduct]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptionValues_ListByProduct]
	@ProductID	Integer = NULL,
	@Active		Smallint = NULL	
AS

SELECT
	V.ProductOptionValueID,
	V.ProductOptionID,
	V.ValueName,
	V.SKU,
	V.PriceDifference,
	V.WeightDifference,
	V.Active,
	V.DisplayOrder,
	V.CreateDate,
	V.ModifyDate
FROM
	ProductOptionValues V
	INNER JOIN ProductOptions O ON V.ProductOptionID = O.ProductOptionID
WHERE
	O.ProductID = @ProductID AND
	V.Active = (CASE WHEN @Active IS NULL THEN V.Active ELSE @Active END) AND
	V.Active > -1
ORDER BY
	V.DisplayOrder
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptions_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptions_Update]
	@ProductOptionID	Integer,
	@OptionName		Varchar(50),
	@Required		Smallint,
	@AllowSKU		Smallint,
	@Active			Smallint,
	@RetVal			Integer Output
AS

DECLARE @ProductID Integer
SET @ProductID = (SELECT ProductID FROM ProductOptions WHERE ProductOptionID = @ProductOptionID)

-- Make sure the update does not make it a duplicate
IF EXISTS(SELECT ProductOptionID FROM ProductOptions WHERE ProductID = @ProductID AND 
		  OptionName = @OptionName AND Active > -1 AND ProductOptionID <> @ProductOptionID)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END

-- If the allow SKU option is turned off, make sure all values are clear of their SKUs
IF @AllowSKU <> 1
	BEGIN
	UPDATE ProductOptionValues SET SKU = NULL WHERE ProductOptionID = @ProductOptionID
	END

UPDATE
	ProductOptions
SET
	OptionName = @OptionName,
	Required = @Required,
	AllowSKU = @AllowSKU,
	Active = @Active,
	ModifyDate = GetDate()
WHERE
	ProductOptionID = @ProductOptionID

-- Return a success indicator
SET @RetVal = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptionValues_ListByOption]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptionValues_ListByOption]
	@ProductOptionID	Integer = NULL,
	@Active			Smallint = NULL	
AS

SELECT
	ProductOptionValueID,
	ProductOptionID,
	ValueName,
	SKU,
	PriceDifference,
	WeightDifference,
	Active,
	DisplayOrder,
	CreateDate,
	ModifyDate
FROM
	ProductOptionValues
WHERE
	ProductOptionID = @ProductOptionID AND
	Active = (CASE WHEN @Active IS NULL THEN Active ELSE @Active END) AND
	Active > -1
ORDER BY
	DisplayOrder
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptionValues_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptionValues_Update]
	@ProductOptionValueID	Integer,
	@ValueName		VarChar(50),
	@SKU			VarChar(50),
	@PriceDifference	Money,
	@WeightDifference	Decimal(18, 4),
	@Active			SmallInt,
	@RetVal			Integer Output
AS

DECLARE @OptionID Integer
SET @OptionID = (SELECT ProductOptionID FROM ProductOptionValues WHERE ProductOptionValueID = @ProductOptionValueID)

IF EXISTS(SELECT * FROM dbo.ProductOptionValues WHERE ProductOptionID = @OptionID AND ValueName = @ValueName AND Active > -1 AND ProductOptionValueID <> @ProductOptionValueID)
	BEGIN
	SET @RetVal = -1
	RETURN
	END

UPDATE
	dbo.ProductOptionValues
SET
	ValueName = @ValueName,
	SKU = @SKU,
	PriceDifference = @PriceDifference,
	WeightDifference = @WeightDifference,
	Active = @Active,
	ModifyDate = GetDate()
WHERE
	ProductOptionValueID = @ProductOptionValueID

SET @RetVal = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptionValues_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptionValues_Delete]
	@ProductOptionValueID	Integer
AS

UPDATE
	dbo.ProductOptionValues 
SET
	Active = -1
WHERE 
	ProductOptionValueID = @ProductOptionValueID
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptionValues_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptionValues_Add]
	@ProductOptionID	Integer,
	@ValueName		VarChar(50),
	@SKU			VarChar(50),
	@PriceDifference	Money,
	@WeightDifference	Decimal(18, 4),
	@Active			SmallInt,
	@RetVal			Integer Output
AS

IF EXISTS(SELECT * FROM dbo.ProductOptionValues WHERE ProductOptionID = @ProductOptionID AND ValueName = @ValueName AND Active > -1)
	BEGIN
	SET @RetVal = -1
	RETURN
	END

DECLARE @Order Integer
SET @Order = (SELECT ISNULL(MAX(DisplayOrder), 0) + 1 FROM ProductOptionValues WHERE ProductOptionID = @ProductOptionID AND Active > -1)

INSERT INTO ProductOptionValues
	(
	ProductOptionID,
	ValueName,
	SKU,
	PriceDifference,
	WeightDifference,
	Active,
	DisplayOrder,
	CreateDate,
	ModifyDate
	)
VALUES
	(
	@ProductOptionID,
	@ValueName,
	@SKU,
	@PriceDifference,
	@WeightDifference,
	@Active,
	@Order,
	GetDate(),
	GetDate()
	)

SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductOptionValues_SetOrder]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductOptionValues_SetOrder]
	@ProductOptionValueID	Integer,
	@DisplayOrder		Integer
AS

UPDATE
	ProductOptionValues
SET
	DisplayOrder = @DisplayOrder,
	ModifyDate = GetDate()
WHERE
	ProductOptionValueID = @ProductOptionValueID

-- Return a success indicator
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderItemOptions_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderItemOptions_Add]
	@OrderItemID		Integer,
	@ProductOptionID	Integer,
	@ProductOptionValueID	Integer,
	@OptionName		VarChar(50),
	@ValueName		VarChar(50),
	@SKU			VarChar(50),
	@PriceDifference	Money,
	@WeightDifference	Decimal(18, 4),
	@RetVal			Integer Output
AS

IF EXISTS(SELECT * FROM dbo.OrderItemOptions WHERE OrderItemID = @OrderItemID AND ProductOptionID = @ProductOptionID AND ProductOptionValueID = @ProductOptionValueID)
	BEGIN
	SET @RetVal = -1
	RETURN
	END

INSERT INTO OrderItemOptions
	(
	OrderItemID,
	ProductOptionID,
	ProductOptionValueID,
	OptionName,
	ValueName,
	SKU,
	PriceDifference,
	WeightDifference,
	CreateDate,
	ModifyDate
	)
VALUES
	(
	@OrderItemID,
	@ProductOptionID,
	@ProductOptionValueID,
	@OptionName,
	@ValueName,
	@SKU,
	@PriceDifference,
	@WeightDifference,
	GetDate(),
	GetDate()
	)

SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderItemOptions_ListByItem]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderItemOptions_ListByItem]
	@OrderItemID	Integer
AS

SELECT
	O.OrderItemOptionID,
	O.OrderItemID,
	O.ProductOptionID,
	O.ProductOptionValueID,
	O.OptionName,
	O.ValueName,
	O.SKU,
	O.PriceDifference,
	O.WeightDifference,
	O.CreateDate,
	O.ModifyDate
FROM
	OrderItemOptions O
WHERE
	O.OrderItemID = @OrderItemID
ORDER BY
	OrderItemOptionID
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderItemOptions_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderItemOptions_Update]
	@OrderItemOptionID	Integer,
	@OrderItemID		Integer,
	@ProductOptionID	Integer,
	@ProductOptionValueID	Integer,
	@OptionName		VarChar(50),
	@ValueName		VarChar(50),
	@SKU			VarChar(50),
	@PriceDifference	Money,
	@WeightDifference	Decimal(18, 4),
	@RetVal			Integer Output
AS

IF EXISTS(SELECT * FROM dbo.OrderItemOptions WHERE OrderItemID = @OrderItemID AND ProductOptionID = @ProductOptionID AND ProductOptionValueID = @ProductOptionValueID AND OrderItemOptionID <> @OrderItemOptionID)
	BEGIN
	SET @RetVal = -1
	RETURN
	END

UPDATE
	dbo.OrderItemOptions
SET
	OrderItemID = @OrderItemID,
	ProductOptionID = @ProductOptionID,
	ProductOptionValueID = @ProductOptionValueID,
	OptionName = @OptionName,
	ValueName = @ValueName,
	SKU = @SKU,
	PriceDifference = @PriceDifference,
	WeightDifference = @WeightDifference,
	ModifyDate = GetDate()
WHERE
	OrderItemOptionID = @OrderItemOptionID

SET @RetVal = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderItemOptions_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderItemOptions_Delete]
	@OrderItemOptionID	Integer
AS

DELETE FROM dbo.OrderItemOptions WHERE OrderItemOptionID = @OrderItemOptionID
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderMemos_ListByOrder]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderMemos_ListByOrder]
	@OrderID	Integer
AS

SELECT
	OrderMemoID,
	OrderID,
	[Memo],
	CreateDate,
	ModifyDate
FROM
	OrderMemos C
WHERE
	OrderID = @OrderID
ORDER BY
	OrderMemoID
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderMemos_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderMemos_Add]
	@OrderID	Integer,
	@Memo		Text,
	@RetVal		Integer Output
AS
	
INSERT INTO OrderMemos
	(
	OrderID,
	[Memo],
	CreateDate, 
	ModifyDate
	)
	VALUES
	(
	@OrderID,
	@Memo,
	GetDate(), 
	GetDate()
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderMemos_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderMemos_Delete]
	@OrderMemoID	Integer
AS

-- Mark the record as deleted
DELETE FROM OrderMemos WHERE OrderMemoID = @OrderMemoID
GO
/****** Object:  StoredProcedure [dbo].[sp_OrderMemos_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_OrderMemos_ListByKey]
	@OrderMemoID       Integer
AS

SELECT
	OrderMemoID,
	OrderID,
	[Memo],
	CreateDate,
	ModifyDate
FROM
	OrderMemos C
WHERE
	OrderMemoID = @OrderMemoID
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_UpdateFeatured]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_UpdateFeatured]
(
	@ProductID INTEGER
)
AS
	SET NOCOUNT ON

	UPDATE Products
	SET ShowFeatured = 0

	UPDATE Products
	SET ShowFeatured = 1
	WHERE ProductID = @ProductID

	RETURN
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_Update]
	@ProductID			Integer,
	@CategoryID			Integer,
	@ProductCode		Varchar(50),
	@ProductName		Varchar(100),
	@Description		Varchar(6000),
	@Keywords			Varchar(200),
	@Cost				Money,
	@RetailPrice		Money,
	@OriginalPrice		Money,
	@Weight				Decimal(18, 4),
	@Inventory			Integer,
	@ShowNew			Smallint,
	@ShowReducedPrice	Smallint,
	@AllowBackorder		Smallint,
	@Active				Smallint,
	@ShowFeatured		Smallint,
	@ShowHomePage		Smallint,
	@FeaturedTitle		VARCHAR(255),
	@FeaturedSubTitle	VARCHAR(255),
	@FeaturedBullet1	VARCHAR(255),
	@FeaturedBullet2	VARCHAR(255),
	@FeaturedBullet3	VARCHAR(255),
	@Sort				INTEGER,
	@RetVal				Integer Output
AS

-- Make sure the update does not make it a duplicate
IF EXISTS(SELECT ProductID FROM Products WHERE ProductCode = @ProductCode AND Active > -1 AND ProductID <> @ProductID)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
--IF EXISTS(SELECT ProductID FROM Products WHERE CategoryID = @CategoryID AND ProductName = @ProductName AND Active > -1 AND ProductID <> @ProductID)
--	BEGIN
--	SET @RetVal = -2  -- Indicate duplicate found
--	RETURN
--	END

UPDATE
	Products
SET
	CategoryID = @CategoryID,
	ProductCode = @ProductCode,
	ProductName = @ProductName,
	[Description] = @Description,
	Keywords = @Keywords,
	Cost = @Cost,
	RetailPrice = @RetailPrice,
	OriginalPrice = @OriginalPrice,
	Weight = @Weight,
	Inventory = @Inventory,
	ShowNew = @ShowNew,
	ShowReducedPrice = @ShowReducedPrice,
	AllowBackorder = @AllowBackorder,
	Active = @Active,
	ModifyDate = GetDate(),
	ShowFeatured = @ShowFeatured,
	ShowHomePage = @ShowHomePage,
	FeaturedTitle=@FeaturedTitle,
	FeaturedSubTitle=@FeaturedSubTitle,
	FeaturedBullet1=@FeaturedBullet1,
	FeaturedBullet2=@FeaturedBullet2,
	FeaturedBullet3=@FeaturedBullet3,
	OldCategoryID=@Sort
WHERE
	ProductID = @ProductID

-- Return a success indicator
SET @RetVal = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_SetImages]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Products_SetImages]
	@ProductID		Integer,
	@ImagePath1		Varchar(200),
	@ImagePath2		Varchar(200),
	@ImagePath3		Varchar(200),
	@ImagePath4		Varchar(200),
	@ImagePath5		Varchar(200),
	@ImagePath6		Varchar(200),
	@ImagePath7		Varchar(200),
	@ImagePath8		Varchar(200),
	@ImagePath9		Varchar(200),
	@ImagePath10	Varchar(200)
AS

UPDATE
	Products
SET
	ImagePath1 = @ImagePath1,
	ImagePath2 = @ImagePath2,
	ImagePath3 = @ImagePath3,
	ImagePath4 = @ImagePath4,
	ImagePath5 = @ImagePath5,
	ImagePath6 = @ImagePath6,
	ImagePath7 = @ImagePath7,
	ImagePath8 = @ImagePath8,
	ImagePath9 = @ImagePath9,
	ImagePath10 = @ImagePath10,
	ModifyDate = GetDate()
WHERE
	ProductID = @ProductID
GO
/****** Object:  StoredProcedure [dbo].[sp_Products_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[sp_Products_Add]
	@CategoryID			Integer,
	@ProductCode		Varchar(50),
	@ProductName		Varchar(100),
	@Description		Varchar(6000),
	@Keywords			Varchar(200),
	@Cost				Money,
	@RetailPrice		Money,
	@OriginalPrice		Money,
	@Weight				Decimal(18, 4),
	@Inventory			Integer,
	@ShowNew			Smallint,
	@ShowReducedPrice	Smallint,
	@AllowBackorder		Smallint,
	@Active				Smallint,
	@ShowFeatured		SMALLINT,
	@ShowHomePage		SMALLINT,
	@FeaturedTitle		VARCHAR(255),
	@FeaturedSubTitle	VARCHAR(255),
	@FeaturedBullet1	VARCHAR(255),
	@FeaturedBullet2	VARCHAR(255),
	@FeaturedBullet3	VARCHAR(255),
	@Sort				INTEGER=NULL,
	@RetVal				Integer Output
AS

-- Make sure this is not a duplicate record
IF EXISTS(SELECT ProductID FROM Products WHERE ProductCode = @ProductCode AND Active > -1)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
-- IF EXISTS(SELECT ProductID FROM Products WHERE CategoryID = @CategoryID AND ProductName = @ProductName AND Active > -1)
-- 	BEGIN
-- 	SET @RetVal = -2  -- Indicate duplicate found
-- 	RETURN
-- 	END
	
INSERT INTO Products
	(
	CategoryID,
	ProductCode,
	ProductName,
	[Description],
	Keywords,
	Cost,
	RetailPrice,
	OriginalPrice,
	Weight,
	Inventory,
	ShowNew,
	ShowReducedPrice,
	AllowBackorder,
	Active,
	CreateDate, 
	ModifyDate,
	ShowFeatured,
	ShowHomePage,
	FeaturedTitle,
	FeaturedSubTitle,
	FeaturedBullet1,
	FeaturedBullet2,
	FeaturedBullet3,
	OldCategoryID
	)
	VALUES
	(
	@CategoryID,
	@ProductCode,
	@ProductName,
	@Description,
	@Keywords,
	@Cost,
	@RetailPrice,
	@OriginalPrice,
	@Weight,
	@Inventory,
	@ShowNew,
	@ShowReducedPrice,
	@AllowBackorder,
	@Active,
	GetDate(), 
	GetDate(),
	@ShowFeatured,
	@ShowHomePage,
	@FeaturedTitle,
	@FeaturedSubTitle,
	@FeaturedBullet1,
	@FeaturedBullet2,
	@FeaturedBullet3,
	@Sort
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductPriceRanges_Add]
(
	 @ProductID		INTEGER
	,@LowerLimit	INTEGER
	,@Limit			INTEGER
	,@Price			MONEY
)	
	
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO ProductPriceRanges
	(
		 ProductID
		,LowerLimit
		,Limit
		,Price
		,Active
	)
	VALUES
	(
		 @ProductID
		,@LowerLimit
		,@Limit
		,@Price
		,1
	)
	
	RETURN
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductPriceRanges_Update]
(
	 @ProductPriceRangeID	INTEGER
	,@LowerLimit			INTEGER
	,@Limit					INTEGER
	,@Price					MONEY
	,@Active				INTEGER
)	
	
AS
BEGIN
	SET NOCOUNT ON

	UPDATE ProductPriceRanges
	SET
		 LowerLimit = @LowerLimit
		,Limit = @Limit
		,Price = @Price
		,Active = @Active
	WHERE
		ProductPriceRangeID = @ProductPriceRangeID
	
	RETURN
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductPriceRanges_ListByKey]
(
	 @ProductPriceRangeID INTEGER
)	
	
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		 ProductPriceRangeID
		,ProductID
		,LowerLimit
		,Limit
		,Price
		,Active
	FROM
		ProductPriceRanges
	WHERE
		ProductPriceRangeID = @ProductPriceRangeID
	
	RETURN
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_List]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductPriceRanges_List]
(
	 @ProductID INTEGER
)	
	
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		 ProductPriceRangeID
		,ProductID
		,LowerLimit
		,Limit
		,Price
		,Active
	FROM
		ProductPriceRanges
	WHERE
		ProductID = @ProductID
	ORDER BY
		Limit ASC
	
	RETURN
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_GetPrice]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_ProductPriceRanges_GetPrice]
	@ProductID INTEGER,
	@Qty INTEGER
AS

SELECT TOP 1
	ProductPriceRangeID,
	ProductID,
	LowerLimit,
	Limit,
	Price,
	Active 
FROM 
	ProductPriceRanges 
WHERE 
		ProductID=@ProductID
AND		Limit >= @Qty
AND		LowerLimit <= @Qty
ORDER BY
	Price DESC
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_DeleteByProductId]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductPriceRanges_DeleteByProductId]
(
	 @ProductID INTEGER
)	
	
AS
BEGIN
	SET NOCOUNT ON

	DELETE FROM ProductPriceRanges
	WHERE ProductID = @ProductID
	
	RETURN
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ProductPriceRanges_GetMinimumQty]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ProductPriceRanges_GetMinimumQty]
(
	@ProductID INTEGER
) AS

/*
** Gets the minimum quantity available to sell
** This value will be one of three cases:
**             1 - If Items set to go from 0+
**            -1 - If product is a normal shopping cart product and does not use the ProductPriceRanges table
**    [LowerLimit] - If the product pricing/qtys are taken from the ProductPriceRanges table
*/
SELECT TOP 1
	(CASE
		WHEN LowerLimit = 0 THEN 1
		WHEN LowerLimit IS NULL THEN 1
		ELSE LowerLimit
	END) AS Value
FROM
	ProductPriceRanges
WHERE
	ProductID = @ProductID
ORDER BY
	LowerLimit ASC
GO
/****** Object:  StoredProcedure [dbo].[sp_Content_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Content_Update] 
	-- Add the parameters for the stored procedure here
	@ContentID Int,
	@Content text,
	@Title varchar(500)
AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Update
	CustomContent
Set
	Content = @Content,
	Title = @Title
Where
	ContentID = @ContentID
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Content_List]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Content_List] 
	-- Add the parameters for the stored procedure here
	@SiteID TinyInt = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Select 
		ContentID,
		Title,
		DateCreated
	From
		CustomContent
	Where
		SiteID = @SiteID
		And Active = 1
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Content_Get]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Content_Get] 
	-- Add the parameters for the stored procedure here
	@SiteId INT = 1,
	@ContentID Int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Select 
		ContentID,
		Title,
		Content,
		DateCreated
	From
		CustomContent
	Where
		ContentID = @ContentID
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Sites_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Sites_Add]
	@SiteCode	Varchar(50),
	@SiteName	Varchar(50),
	@SiteURL	Varchar(200),
	@Active		Smallint,
	@RetVal		Integer Output
AS

-- Make sure this is not a duplicate record
IF EXISTS(SELECT SiteID FROM Sites WHERE SiteCode = @SiteCode AND Active > -1)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
IF EXISTS(SELECT SiteID FROM Sites WHERE SiteName = @SiteName AND Active > -1)
	BEGIN
	SET @RetVal = -2  -- Indicate duplicate found
	RETURN
	END
IF EXISTS(SELECT SiteID FROM Sites WHERE SiteURL = @SiteURL AND Active > -1)
	BEGIN
	SET @RetVal = -3  -- Indicate duplicate found
	RETURN
	END
	
INSERT INTO Sites
	(
	SiteCode,
	SiteName, 
	SiteURL,
	Active,
	CreateDate, 
	ModifyDate
	)
	VALUES
	(
	@SiteCode,
	@SiteName, 
	@SiteURL,
	@Active,
	GetDate(), 
	GetDate()
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_Sites_Delete]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Sites_Delete]
	@SiteID	Integer
AS

-- Mark the record as deleted
UPDATE 
	Sites 
SET
	Active = -1
WHERE
	SiteID = @SiteID
GO
/****** Object:  StoredProcedure [dbo].[sp_Sites_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Sites_Update]
	@SiteID	Integer,
	@SiteCode	Varchar(50),
	@SiteName	Varchar(50),
	@SiteURL	Varchar(200),
	@Active		Smallint,
	@RetVal		Integer Output
AS

-- Make sure the update does not make it a duplicate
IF EXISTS(SELECT SiteID FROM Sites WHERE SiteCode = @SiteCode AND SiteID <> @SiteID AND Active > -1)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
IF EXISTS(SELECT SiteID FROM Sites WHERE SiteName = @SiteName AND SiteID <> @SiteID AND Active > -1)
	BEGIN
	SET @RetVal = -2  -- Indicate duplicate found
	RETURN
	END
IF EXISTS(SELECT SiteID FROM Sites WHERE SiteURL = @SiteURL AND SiteID <> @SiteID AND Active > -1)
	BEGIN
	SET @RetVal = -3  -- Indicate duplicate found
	RETURN
	END

UPDATE
	Sites
SET
	SiteCode = @SiteCode,
	SiteName = @SiteName,
	SiteURL = @SiteURL,
	Active = @Active,
	ModifyDate = GetDate()
WHERE
	SiteID = @SiteID

-- Return a success indicator
SET @RetVal = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_Sites_ListByKey]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Sites_ListByKey]
	@SiteID       Integer
AS

SELECT
	S.SiteID,
	S.SiteCode,
	S.SiteName,
	S.SiteURL,
	S.Active,
	S.CreateDate,
	S.ModifyDate
FROM
	Sites s
WHERE
	S.SiteID = @SiteID
GO
/****** Object:  StoredProcedure [dbo].[sp_Sites_List]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Sites_List]
	@Active		Smallint = NULL
AS

SELECT
	S.SiteID,
	S.SiteCode,
	S.SiteName,
	S.SiteURL,
	S.Active,
	S.CreateDate,
	S.ModifyDate
FROM
	Sites S
WHERE
	Active = (CASE WHEN @Active IS NULL THEN S.Active ELSE @Active END) AND
	Active > -1
ORDER BY
	S.SiteName
GO
/****** Object:  StoredProcedure [dbo].[sp_States_Add]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_States_Add]
	@StateCode	Varchar(50),
	@StateName	Varchar(50),
	@SalesTax	Decimal(18, 4),
	@RetVal		Integer Output
AS

-- Make sure this is not a duplicate record
IF EXISTS(SELECT StateID FROM States WHERE StateCode = @StateCode)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
IF EXISTS(SELECT StateID FROM States WHERE StateName = @StateName)
	BEGIN
	SET @RetVal = -2  -- Indicate duplicate found
	RETURN
	END
	
INSERT INTO States
	(
	StateCode,
	StateName, 
	SalesTax,
	CreateDate, 
	ModifyDate
	)
	VALUES
	(
	@StateCode,
	@StateName, 
	@SalesTax,
	GetDate(), 
	GetDate()
	)

-- Get the new ID of the record
SET @RetVal = @@IDENTITY
GO
/****** Object:  StoredProcedure [dbo].[sp_States_List]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_States_List] AS

SELECT
	S.StateID,
	S.StateCode,
	S.StateName,
	S.SalesTax,
	S.CreateDate,
	S.ModifyDate
FROM
	States S
ORDER BY
	S.StateCode
GO
/****** Object:  StoredProcedure [dbo].[sp_States_Update]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_States_Update]
	@StateID	Integer,
	@StateCode	Varchar(50),
	@StateName	Varchar(50),
	@SalesTax	Decimal(18, 4),
	@RetVal		Integer Output
AS

-- Make sure the update does not make it a duplicate
IF EXISTS(SELECT StateID FROM States WHERE StateCode = @StateCode AND StateID <> @StateID)
	BEGIN
	SET @RetVal = -1  -- Indicate duplicate found
	RETURN
	END
IF EXISTS(SELECT StateID FROM States WHERE StateName = @StateName AND StateID <> @StateID)
	BEGIN
	SET @RetVal = -2  -- Indicate duplicate found
	RETURN
	END

UPDATE
	States
SET
	StateCode = @StateCode,
	StateName = @StateName,
	SalesTax = @SalesTax,
	ModifyDate = GetDate()
WHERE
	StateID = @StateID

-- Return a success indicator
SET @RetVal = 1
GO
/****** Object:  StoredProcedure [dbo].[sp_States_SetTax]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_States_SetTax]
	@StateCode	Varchar(2),
	@SalesTax	Decimal(18, 4)
AS

UPDATE
	States
SET
	SalesTax = @SalesTax,
	ModifyDate = GetDate()
WHERE
	StateCode = @StateCode
GO
/****** Object:  StoredProcedure [dbo].[sp_States_ListByCode]    Script Date: 05/17/2012 14:14:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_States_ListByCode]
	@StateCode	Varchar(2)
AS

SELECT
	S.StateID,
	S.StateCode,
	S.StateName,
	S.SalesTax,
	S.CreateDate,
	S.ModifyDate
FROM
	States s
WHERE
	S.StateCode = @StateCode
GO
/****** Object:  Default [DF_Coupons_Active]    Script Date: 05/17/2012 14:14:10 ******/
ALTER TABLE [dbo].[Coupons] ADD  CONSTRAINT [DF_Coupons_Active]  DEFAULT ((1)) FOR [Active]
GO
/****** Object:  Default [DF_Coupons_CreateDate]    Script Date: 05/17/2012 14:14:10 ******/
ALTER TABLE [dbo].[Coupons] ADD  CONSTRAINT [DF_Coupons_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_Coupons_ModifyDate]    Script Date: 05/17/2012 14:14:10 ******/
ALTER TABLE [dbo].[Coupons] ADD  CONSTRAINT [DF_Coupons_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_Categories_Active]    Script Date: 05/17/2012 14:14:10 ******/
ALTER TABLE [dbo].[Categories] ADD  CONSTRAINT [DF_Categories_Active]  DEFAULT ((1)) FOR [Active]
GO
/****** Object:  Default [DF_Categories_CreateDate]    Script Date: 05/17/2012 14:14:10 ******/
ALTER TABLE [dbo].[Categories] ADD  CONSTRAINT [DF_Categories_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_Categories_ModifyDate]    Script Date: 05/17/2012 14:14:10 ******/
ALTER TABLE [dbo].[Categories] ADD  CONSTRAINT [DF_Categories_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_NewsletterSubscriptions_SignupDate]    Script Date: 05/17/2012 14:14:10 ******/
ALTER TABLE [dbo].[NewsletterSubscriptions] ADD  CONSTRAINT [DF_NewsletterSubscriptions_SignupDate]  DEFAULT (getdate()) FOR [SignupDate]
GO
/****** Object:  Default [DF__dtpropert__versi__108B795B]    Script Date: 05/17/2012 14:14:13 ******/
ALTER TABLE [dbo].[dtproperties] ADD  CONSTRAINT [DF__dtpropert__versi__108B795B]  DEFAULT ((0)) FOR [version]
GO
/****** Object:  Default [DF_Settings_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Settings] ADD  CONSTRAINT [DF_Settings_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_Settings_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Settings] ADD  CONSTRAINT [DF_Settings_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_CustomContent_DateCreated]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[CustomContent] ADD  CONSTRAINT [DF_CustomContent_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
GO
/****** Object:  Default [DF_Sites_Active]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Sites] ADD  CONSTRAINT [DF_Sites_Active]  DEFAULT ((1)) FOR [Active]
GO
/****** Object:  Default [DF_Sites_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Sites] ADD  CONSTRAINT [DF_Sites_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_Sites_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Sites] ADD  CONSTRAINT [DF_Sites_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_States_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[States] ADD  CONSTRAINT [DF_States_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_States_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[States] ADD  CONSTRAINT [DF_States_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_Orders_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Orders] ADD  CONSTRAINT [DF_Orders_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_Orders_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Orders] ADD  CONSTRAINT [DF_Orders_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_SiteCategories_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[SiteCategories] ADD  CONSTRAINT [DF_SiteCategories_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_SiteCategories_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[SiteCategories] ADD  CONSTRAINT [DF_SiteCategories_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_Products_Inventory]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_Inventory]  DEFAULT ((0)) FOR [Inventory]
GO
/****** Object:  Default [DF_Products_ShowNew]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_ShowNew]  DEFAULT ((0)) FOR [ShowNew]
GO
/****** Object:  Default [DF_Products_ShowReducedPrice]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_ShowReducedPrice]  DEFAULT ((0)) FOR [ShowReducedPrice]
GO
/****** Object:  Default [DF_Products_AllowBackorder]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_AllowBackorder]  DEFAULT ((0)) FOR [AllowBackorder]
GO
/****** Object:  Default [DF_Products_Active]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_Active]  DEFAULT ((1)) FOR [Active]
GO
/****** Object:  Default [DF_Products_System]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_System]  DEFAULT ((0)) FOR [System]
GO
/****** Object:  Default [DF_Products_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_Products_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_OrderItems_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItems] ADD  CONSTRAINT [DF_OrderItems_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_OrderItems_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItems] ADD  CONSTRAINT [DF_OrderItems_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_OrderMemos_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderMemos] ADD  CONSTRAINT [DF_OrderMemos_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_OrderMemos_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderMemos] ADD  CONSTRAINT [DF_OrderMemos_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_OrderItemOptions_WeightDifference]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItemOptions] ADD  CONSTRAINT [DF_OrderItemOptions_WeightDifference]  DEFAULT ((0)) FOR [WeightDifference]
GO
/****** Object:  Default [DF_OrderItemOptions_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItemOptions] ADD  CONSTRAINT [DF_OrderItemOptions_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_OrderItemOptions_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItemOptions] ADD  CONSTRAINT [DF_OrderItemOptions_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_ProductOptionValues_PriceDifference]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptionValues] ADD  CONSTRAINT [DF_ProductOptionValues_PriceDifference]  DEFAULT ((0)) FOR [PriceDifference]
GO
/****** Object:  Default [DF_ProductOptionValues_WeightDifference]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptionValues] ADD  CONSTRAINT [DF_ProductOptionValues_WeightDifference]  DEFAULT ((0)) FOR [WeightDifference]
GO
/****** Object:  Default [DF_ProductOptionValues_Active]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptionValues] ADD  CONSTRAINT [DF_ProductOptionValues_Active]  DEFAULT ((1)) FOR [Active]
GO
/****** Object:  Default [DF_ProductOptionValues_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptionValues] ADD  CONSTRAINT [DF_ProductOptionValues_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_ProductOptionValues_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptionValues] ADD  CONSTRAINT [DF_ProductOptionValues_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_ProductOptions_Required]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptions] ADD  CONSTRAINT [DF_ProductOptions_Required]  DEFAULT ((1)) FOR [Required]
GO
/****** Object:  Default [DF_ProductOptions_AllowSKU]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptions] ADD  CONSTRAINT [DF_ProductOptions_AllowSKU]  DEFAULT ((0)) FOR [AllowSKU]
GO
/****** Object:  Default [DF_ProductOptions_Active]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptions] ADD  CONSTRAINT [DF_ProductOptions_Active]  DEFAULT ((1)) FOR [Active]
GO
/****** Object:  Default [DF_ProductOptions_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptions] ADD  CONSTRAINT [DF_ProductOptions_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_ProductOptions_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptions] ADD  CONSTRAINT [DF_ProductOptions_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_SiteProducts_CreateDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[SiteProducts] ADD  CONSTRAINT [DF_SiteProducts_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_SiteProducts_ModifyDate]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[SiteProducts] ADD  CONSTRAINT [DF_SiteProducts_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  ForeignKey [FK_Categories_Categories]    Script Date: 05/17/2012 14:14:10 ******/
ALTER TABLE [dbo].[Categories]  WITH CHECK ADD  CONSTRAINT [FK_Categories_Categories] FOREIGN KEY([ParentID])
REFERENCES [dbo].[Categories] ([CategoryID])
GO
ALTER TABLE [dbo].[Categories] CHECK CONSTRAINT [FK_Categories_Categories]
GO
/****** Object:  ForeignKey [FK_Orders_Coupons]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Coupons] FOREIGN KEY([CouponID])
REFERENCES [dbo].[Coupons] ([CouponID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Coupons]
GO
/****** Object:  ForeignKey [FK_Orders_Sites]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Sites] FOREIGN KEY([SiteID])
REFERENCES [dbo].[Sites] ([SiteID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Sites]
GO
/****** Object:  ForeignKey [FK_SiteCategories_Categories]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[SiteCategories]  WITH CHECK ADD  CONSTRAINT [FK_SiteCategories_Categories] FOREIGN KEY([CategoryID])
REFERENCES [dbo].[Categories] ([CategoryID])
GO
ALTER TABLE [dbo].[SiteCategories] CHECK CONSTRAINT [FK_SiteCategories_Categories]
GO
/****** Object:  ForeignKey [FK_SiteCategories_Sites]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[SiteCategories]  WITH CHECK ADD  CONSTRAINT [FK_SiteCategories_Sites] FOREIGN KEY([SiteID])
REFERENCES [dbo].[Sites] ([SiteID])
GO
ALTER TABLE [dbo].[SiteCategories] CHECK CONSTRAINT [FK_SiteCategories_Sites]
GO
/****** Object:  ForeignKey [FK_Products_Categories]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[Products]  WITH CHECK ADD  CONSTRAINT [FK_Products_Categories] FOREIGN KEY([CategoryID])
REFERENCES [dbo].[Categories] ([CategoryID])
GO
ALTER TABLE [dbo].[Products] CHECK CONSTRAINT [FK_Products_Categories]
GO
/****** Object:  ForeignKey [FK_OrderItems_Orders]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItems]  WITH CHECK ADD  CONSTRAINT [FK_OrderItems_Orders] FOREIGN KEY([OrderID])
REFERENCES [dbo].[Orders] ([OrderID])
GO
ALTER TABLE [dbo].[OrderItems] CHECK CONSTRAINT [FK_OrderItems_Orders]
GO
/****** Object:  ForeignKey [FK_OrderItems_Products]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItems]  WITH CHECK ADD  CONSTRAINT [FK_OrderItems_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ProductID])
GO
ALTER TABLE [dbo].[OrderItems] CHECK CONSTRAINT [FK_OrderItems_Products]
GO
/****** Object:  ForeignKey [FK_OrderMemos_Orders]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderMemos]  WITH CHECK ADD  CONSTRAINT [FK_OrderMemos_Orders] FOREIGN KEY([OrderID])
REFERENCES [dbo].[Orders] ([OrderID])
GO
ALTER TABLE [dbo].[OrderMemos] CHECK CONSTRAINT [FK_OrderMemos_Orders]
GO
/****** Object:  ForeignKey [FK_OrderItemOptions_OrderItems]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItemOptions]  WITH CHECK ADD  CONSTRAINT [FK_OrderItemOptions_OrderItems] FOREIGN KEY([OrderItemID])
REFERENCES [dbo].[OrderItems] ([OrderItemID])
GO
ALTER TABLE [dbo].[OrderItemOptions] CHECK CONSTRAINT [FK_OrderItemOptions_OrderItems]
GO
/****** Object:  ForeignKey [FK_OrderItemOptions_ProductOptions]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItemOptions]  WITH CHECK ADD  CONSTRAINT [FK_OrderItemOptions_ProductOptions] FOREIGN KEY([ProductOptionID])
REFERENCES [dbo].[ProductOptions] ([ProductOptionID])
GO
ALTER TABLE [dbo].[OrderItemOptions] CHECK CONSTRAINT [FK_OrderItemOptions_ProductOptions]
GO
/****** Object:  ForeignKey [FK_OrderItemOptions_ProductOptionValues]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[OrderItemOptions]  WITH CHECK ADD  CONSTRAINT [FK_OrderItemOptions_ProductOptionValues] FOREIGN KEY([ProductOptionValueID])
REFERENCES [dbo].[ProductOptionValues] ([ProductOptionValueID])
GO
ALTER TABLE [dbo].[OrderItemOptions] CHECK CONSTRAINT [FK_OrderItemOptions_ProductOptionValues]
GO
/****** Object:  ForeignKey [FK_ProductOptionValues_ProductOptions]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptionValues]  WITH CHECK ADD  CONSTRAINT [FK_ProductOptionValues_ProductOptions] FOREIGN KEY([ProductOptionID])
REFERENCES [dbo].[ProductOptions] ([ProductOptionID])
GO
ALTER TABLE [dbo].[ProductOptionValues] CHECK CONSTRAINT [FK_ProductOptionValues_ProductOptions]
GO
/****** Object:  ForeignKey [FK_ProductOptions_Products]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[ProductOptions]  WITH CHECK ADD  CONSTRAINT [FK_ProductOptions_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ProductID])
GO
ALTER TABLE [dbo].[ProductOptions] CHECK CONSTRAINT [FK_ProductOptions_Products]
GO
/****** Object:  ForeignKey [FK_SiteProducts_Products]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[SiteProducts]  WITH CHECK ADD  CONSTRAINT [FK_SiteProducts_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ProductID])
GO
ALTER TABLE [dbo].[SiteProducts] CHECK CONSTRAINT [FK_SiteProducts_Products]
GO
/****** Object:  ForeignKey [FK_SiteProducts_Sites]    Script Date: 05/17/2012 14:14:14 ******/
ALTER TABLE [dbo].[SiteProducts]  WITH CHECK ADD  CONSTRAINT [FK_SiteProducts_Sites] FOREIGN KEY([SiteID])
REFERENCES [dbo].[Sites] ([SiteID])
GO
ALTER TABLE [dbo].[SiteProducts] CHECK CONSTRAINT [FK_SiteProducts_Sites]
GO
