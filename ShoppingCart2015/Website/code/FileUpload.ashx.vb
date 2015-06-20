Imports System.Web
Imports System.Web.Services
Imports System.IO
Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Drawing.Imaging
Public Class FileUpload
    Implements System.Web.IHttpHandler

    Public Shared Function ResizeImage(ByVal image As Image, ByVal size As Size, Optional ByVal preserveAspectRatio As Boolean = True) As Image
        Dim newWidth As Integer
        Dim newHeight As Integer
        If preserveAspectRatio Then
            Dim originalWidth As Integer = image.Width
            Dim originalHeight As Integer = image.Height
            Dim percentWidth As Single = CSng(size.Width) / CSng(originalWidth)
            Dim percentHeight As Single = CSng(size.Height) / CSng(originalHeight)
            Dim percent As Single = If(percentHeight < percentWidth,
                    percentHeight, percentWidth)
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

    Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        'we are not going to do any image resizing here because the imageProcessor will take care of resizing

        context.Response.ContentType = "text/plain"
        Dim uploadFiles As HttpPostedFile = context.Request.Files("Filedata")


        'figure out what this is and find the location to save it in
        '//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        Dim pathToSave As String = ""

        'what are we uploading
        'adding a GUID so that nothing gets overwritten
        Select Case context.Request("uploadtype").ToLower
            Case "categoryimage"
                pathToSave = HttpContext.Current.Server.MapPath(System.Configuration.ConfigurationManager.AppSettings("CategoryImagesFolder")) & "\" & Guid.NewGuid.ToString & "_" & uploadFiles.FileName
            Case "productimage"
                pathToSave = HttpContext.Current.Server.MapPath(System.Configuration.ConfigurationManager.AppSettings("ProductImagesFolder")) & "\" & Guid.NewGuid.ToString & "_" & uploadFiles.FileName
            Case "pdf"
                pathToSave = HttpContext.Current.Server.MapPath(System.Configuration.ConfigurationManager.AppSettings("pdfFolder")) & "\" & Guid.NewGuid.ToString & "_" & uploadFiles.FileName
            Case "blogimage"
                pathToSave = HttpContext.Current.Server.MapPath(System.Configuration.ConfigurationManager.AppSettings("BlogImagesFolder")) & "\" & Guid.NewGuid.ToString & "_" & uploadFiles.FileName
            Case Else
                pathToSave = ""
        End Select
        '//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        'get the filetype
        Dim filetype As String = uploadFiles.FileName.Substring(uploadFiles.FileName.LastIndexOf("."), uploadFiles.FileName.Length - uploadFiles.FileName.LastIndexOf("."))

        If pathToSave <> "" Then
            uploadFiles.SaveAs(pathToSave)
        End If

        'going to return the path to the new image now
        Dim StoragePath = pathToSave.Substring(pathToSave.LastIndexOf("\"), pathToSave.Length - pathToSave.LastIndexOf("\"))
        StoragePath = Replace(StoragePath, "\", "/")
        context.Response.Write(System.Configuration.ConfigurationManager.AppSettings("CategoryImagesFolder") & StoragePath)
        'context.Response.Write("asdfasdfadsfadfa")
        'context.Response.StatusCode = 200
        '
    End Sub

    ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property
End Class