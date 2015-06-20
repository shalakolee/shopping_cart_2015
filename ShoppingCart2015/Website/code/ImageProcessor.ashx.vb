' coded by:
'  ___  __    _______   __  _____  ___  __ _____ __ __  _____  
' ||=|| \\ /\ //||==   ((  ((   )) || \/ | ||==  ||<<  ((   )) 
' || ||  \V/\V/ ||___ \_))  \\_//  ||    | ||___ || \\  \\_//  
'--------------------------------------------------------------
'561media.com
'20140411
Imports System.IO
Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Drawing.Imaging

''' <summary>
'''  This will handle images and write them to memory instead of the hard disk
''' </summary>
''' <remarks>
''' usage:img src="<%="imageprocessor.ashx?image=IMAGEVIRTUALPATH&w=WIDTH&h=HEIGHT&preserve=TRUE/FALSE"%>" 
''' notes: you need to provide the full virtual path. if you want to preserve the aspect ratio, set preserve to "true"
'''        you dont want to pass in a physical path because it will be visible to the user.
''' </remarks>

Public Class ImageProcessor
    Implements System.Web.IHttpHandler
    Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest


        'get image size thats passed in
        Dim Width As Integer = Int32.Parse(context.Request.QueryString("w"))
        Dim Height As Integer = Int32.Parse(context.Request.QueryString("h"))
        Dim myNewSize As New Size(Width, Height)

        'get image thats passed in
        Dim myImage As Image
        Dim myImagePath As String = context.Request.QueryString("image")

        'verify there is an image, if not return the blank one (storing in web.config)
        If Not File.Exists(context.Server.MapPath(myImagePath)) Then
            myImagePath = ConfigurationManager.AppSettings("NoImagePath")
            myImage = Image.FromFile(context.Server.MapPath(ConfigurationManager.AppSettings("NoImagePath")))
        Else
            myImagePath = context.Request.QueryString("image")
            myImage = Image.FromFile(context.Server.MapPath(myImagePath))
        End If

        'lets get the type of image (png, jpg etc) because i want to use it later
        Dim myFileType = myImagePath.Substring(myImagePath.LastIndexOf("."), myImagePath.Length - myImagePath.LastIndexOf("."))

        'optional preserve aspect ratio
        Dim preserveAspectRatio As Boolean = True
        If context.Request.QueryString("preserve") = "" Then
            preserveAspectRatio = False
        End If

        'lets resize the image
        Dim myResizedImage As Image = ResizeImage(myImage, myNewSize, preserveAspectRatio)

        'TODO: crop the image here


        Dim myMemoryStream As MemoryStream = New MemoryStream()
        myResizedImage.Save(myMemoryStream, ImageFormat.Jpeg)
        'lets clear the resized image (memory)
        myResizedImage.Dispose()

        myMemoryStream.WriteTo(context.Response.OutputStream)
        'lets clear and close the stream (memory)
        myMemoryStream.Dispose()
        myMemoryStream.Close()

        'lets write the response (the image)
        context.Response.ContentType = ".jpg"
        context.Response.End()

    End Sub
    Public Shared Function ResizeImage(ByVal image As Image, ByVal size As Size, Optional ByVal preserveAspectRatio As Boolean = True) As Image

        Dim newWidth As Integer
        Dim newHeight As Integer

        If preserveAspectRatio Then
            'get original dimensions
            Dim originalWidth As Integer = image.Width
            Dim originalHeight As Integer = image.Height

            'get the percentage to resize the image with
            Dim percentWidth As Single = CSng(size.Width) / CSng(originalWidth)
            Dim percentHeight As Single = CSng(size.Height) / CSng(originalHeight)

            Dim percent As Single = If(percentHeight < percentWidth, percentHeight, percentWidth)
            'resize the image using percentages
            newWidth = CInt(originalWidth * percent)
            newHeight = CInt(originalHeight * percent)
        Else
            newWidth = size.Width
            newHeight = size.Height
        End If
        Dim newImage As Image = New Bitmap(newWidth, newHeight)

        Using graphicsHandle As Graphics = Graphics.FromImage(newImage)

            graphicsHandle.InterpolationMode = InterpolationMode.HighQualityBicubic
            graphicsHandle.DrawImage(image, 0, 0, newWidth, newHeight)

        End Using
        Return newImage
    End Function

    ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property


End Class