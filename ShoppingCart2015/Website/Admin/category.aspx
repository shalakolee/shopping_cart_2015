<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Admin/admin.Master" CodeBehind="category.aspx.vb" Inherits="Website.adminCategory" ValidateRequest="false" %>

<asp:Content ID="Content1" ContentPlaceHolderID="headContent" runat="server">
    <script src="scripts/uploadify/jquery.uploadify.js"></script>
    <link href="scripts/uploadify/uploadify.css" rel="stylesheet" />
    <script src="scripts/ckeditor/ckeditor.js"></script>

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="bodyContent" runat="server">
    <script>
        //set the sidemenu to the right location
        $(document).ready(function () {
            $('#sidemenu-contentmanagement').addClass("active");
            $('#sidemenu-contentmanagement').find("ul").addClass("in");
            $('#sidemenu-contentmanagement').find("ul").find("li:nth-child(1)").css('background-color', '#EEEEEE');

        });

        ////////////////////////////////////////////////////////////////////////////////////////////////////
        //
        // uploadify javascript 
        //
        ////////////////////////////////////////////////////////////////////////////////////////////////////
        $(document).ready(function () {
            //get folder path from web.config
            var folderpath = '<%=ConfigurationManager.AppSettings("CategoryImagesFolder") & "/"%>';
            //document ready
            $(function () {
                $("#imgUpload1").uploadify({
                    'swf': 'scripts/uploadify/uploadify.swf',
                    'uploader': '/code/FileUpload.ashx?uploadtype=categoryimage',
                    'fileTypeExts': '*.jpg;*.jpeg;*.gif;*.png',
                    'buttonText': 'Choose Image',
                    'multi': false,
                    'auto': true,
                    'onUploadSuccess': function (file, data, response) {
                        // going to set the image
                        $('#Image1').attr('src', data);
                        $('#Image1').css('display', '');
                        //going to set the textbox variables so that they will write to the database
                        $('#txtImage1').val('' + data)
                    }
                });
            });
            $(function () {
                $("#imgUpload2").uploadify({
                    'swf': 'scripts/uploadify/uploadify.swf',
                    'uploader': '/code/FileUpload.ashx?uploadtype=categoryimage',
                    'fileTypeExts': '*.jpg;*.jpeg;*.gif;*.png',
                    'buttonText': 'Choose Image',
                    'multi': false,
                    'auto': true,
                    'onUploadSuccess': function (file, data, response) {
                        // going to set the image
                        $('#Image2').attr('src', data);
                        $('#Image2').css('display', '');

                        //going to set the textbox variables so that they will write to the database
                        $('#txtImage2').val('' + data)
                    }
                });
            });
            $(function () {
                $("#imgUpload3").uploadify({
                    'swf': 'scripts/uploadify/uploadify.swf',
                    'uploader': '/code/FileUpload.ashx?uploadtype=categoryimage',
                    'fileTypeExts': '*.jpg;*.jpeg;*.gif;*.png',
                    'buttonText': 'Choose Image',
                    'multi': false,
                    'auto': true,
                    'onUploadSuccess': function (file, data, response) {
                        // going to set the image
                        $('#Image3').attr('src', data);
                        $('#Image3').css('display', '');

                        //going to set the textbox variables so that they will write to the database
                        $('#txtImage3').val('' + data)
                    }
                });
            });
            $(function () {
                $("#imgUpload4").uploadify({
                    'swf': 'scripts/uploadify/uploadify.swf',
                    'uploader': '/code/FileUpload.ashx?uploadtype=categoryimage',
                    'fileTypeExts': '*.jpg;*.jpeg;*.gif;*.png',
                    'buttonText': 'Choose Image',
                    'multi': false,
                    'auto': true,
                    'onUploadSuccess': function (file, data, response) {
                        // going to set the image
                        $('#Image4').attr('src', data);
                        $('#Image4').css('display', '');
                        //going to set the textbox variables so that they will write to the database
                        $('#txtImage4').val('' + data);

                    }
                });
            });
        });
        ////////////////////////////////////////////////////////////////////////////////////////////////////

    </script>

    <style>
        label {
            font-weight: normal;
        }
        /*center the uploadify objects*/
        .uploadify,
        .uploadify-queue,
        .uploadify-queue-item {
            margin: auto;
        }
    </style>
    <div class="row">
        <div class="col-lg-12">
            <%If CategoryID IsNot Nothing Then%>
            <h1 class="page-header">Editing <%=oCategory.categoryname%></h1>
            <%Else%>
            <h1 class="page-header">Creating a new category</h1>
            <%End If%>
        </div>
        <!-- /.col-lg-12 -->
    </div>
    <div class="panel panel-default">
        <div class="panel-heading">General Information</div>
        <div class="panel-body">
            <!-- Nav tabs -->
            <ul id="myTab" class="nav nav-tabs">
                <li id="GeneralTab" class="active"><a href="#tabGeneral" data-toggle="tab">General Information</a></li>
                <li id="SEOTab"><a href="#tabSEO" data-toggle="tab">SEO Settings</a></li>
                <li id="otherTab"><a href="#tabOther" data-toggle="tab">Other Details</a></li>
                <li id="imagesTab"><a href="#tabImages" data-toggle="tab">Images</a></li>
            </ul>
            <script>
                $(document).ready(function () {

                    $('#myTab a').click(function (e) {
                        // get the current tab and validate its contents
                        var activeID = $("#myTab li.active").attr("id");

                        if (activeID == "GeneralTab") {
                            var pageValidated = false;
                            pageValidated = Page_ClientValidate("vInformation");
                            if (pageValidated) {
                                $(this).tab('show');
                            } else {
                                return false;
                            }
                        }
                        if (activeID == "otherTab") {
                            var pageValidated = false;
                            pageValidated = Page_ClientValidate("vInformation");
                            if (pageValidated) {
                                $(this).tab('show');
                            } else {
                                return false;
                            }
                        }
                        if (activeID == "imagesTab") {
                            var pageValidated = false;
                            pageValidated = Page_ClientValidate("vInformation");
                            if (pageValidated) {
                                $(this).tab('show');
                            } else {
                                return false;
                            }
                        }
                    });
                    /* set specific heights to the ckeditor boxes */
                    CKEDITOR.replace('<%=txtMiniDescription.ClientID%>', { height: '100px' });
                    CKEDITOR.replace('<%=txtDescription.ClientID%>', { height: '200px' });
                });
            </script>
            <!-- /Nav tabs -->


            <div class="tab-content" style="border-left: 1px solid #dddddd; border-right: 1px solid #dddddd; border-bottom: 1px solid #dddddd;">
                <div id="tabGeneral" class="tab-pane fade in active " style="text-align: left;">
                    <div class="panel-body">
                        <asp:ValidationSummary ID="vInformation" runat="server" ShowMessageBox="false" ShowSummary="false" ValidationGroup="vInformation" />
                        <div>
                            <div style="width: 49%; float: left;">
                                <label>Parent Category</label>
                                <asp:DropDownList ID="ddlParentCategory" CssClass="form-control" runat="server"></asp:DropDownList>
                            </div>
                            <div style="width: 49%; float: right;">
                                <label>Category Name</label>
                                <asp:RequiredFieldValidator runat="server" ID="reqCategoryName" ControlToValidate="txtCategoryName" ErrorMessage="* Category Name is Required." Display="dynamic" ValidationGroup="vInformation" />
                                <asp:TextBox ID="txtCategoryName" CssClass="form-control" runat="server"></asp:TextBox>
                            </div>
                        </div>
                        <div style="clear: both; height: 20px;"></div>
                        <div class="formRow">
                            <label>Category Mini-Description</label>
                            <asp:TextBox TextMode="MultiLine" ClientIDMode="static" ID="txtMiniDescription" class="ckeditor" runat="server"></asp:TextBox>
                        </div>
                        <div style="clear: both; height: 20px;"></div>
                        <div class="formRow">
                            <label>Category Description</label>
                            <asp:TextBox TextMode="MultiLine" ClientIDMode="static" ID="txtDescription" class="ckeditor" runat="server"></asp:TextBox>
                        </div>

                    </div>
                </div>
                <div id="tabSEO" class="tab-pane fade in" style="text-align: left;">
                    <div class="panel-body">
                        <div class="formRow">
                            <label>Page Title</label>
                            <asp:TextBox ID="txtSEOTitle" runat="server" CssClass="form-control"></asp:TextBox>
                        </div>
                        <div style="clear: both; height: 20px;"></div>
                        <div class="formRow">
                            <label>Page Slug</label>
                            <asp:TextBox ID="txtSEOSlug" runat="server" CssClass="form-control"></asp:TextBox>
                        </div>
                        <div style="clear: both; height: 20px;"></div>
                        <div class="formRow">
                            <label>Meta Description</label>
                            <asp:TextBox ID="txtSEOMetaDesc" runat="server" CssClass="form-control"></asp:TextBox>
                        </div>
                        <div style="clear: both; height: 20px;"></div>
                        <div class="formRow">
                            <label>Meta Keywords</label>
                            <asp:TextBox ID="txtSEOMetaKeywords" runat="server" CssClass="form-control"></asp:TextBox>
                        </div>
                    </div>
                </div>
                <div id="tabOther" class="tab-pane fade in" style="text-align: left;">
                    <div class="panel-body">
                        <div>
                            <div style="width: 49%; float: left;">
                                <label>Featured</label>
                                <asp:DropDownList ID="ddlFeatured" runat="server" CssClass="form-control">
                                    <asp:ListItem>No</asp:ListItem>
                                    <asp:ListItem>Yes</asp:ListItem>
                                </asp:DropDownList>
                            </div>
                            <div style="width: 49%; float: right;">
                                <label>Sort Order</label>
                                <asp:TextBox ID="txtSortOrder" runat="server" CssClass="form-control" Text="0" />
                            </div>
                        </div>
                        <div style="clear: both; height: 20px;"></div>
                        <div class="formRow">
                            <label>Status</label>
                            <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-control">
                                <asp:ListItem Value="Active">Active</asp:ListItem>
                                <asp:ListItem Value="Inactive">Inactive</asp:ListItem>
                            </asp:DropDownList>
                        </div>
                        <div style="clear: both; height: 20px;"></div>
                    </div>
                </div>
                <div id="tabImages" class="tab-pane fade in" style="text-align: left;">
                    <div class="panel-body">
                        <div>
                            <div class="formRow">
                                <label>Image #1</label>
                                <div class="thumbnail" style="padding-top: 10px;">
                                    <img id="Image1" src="<% If CategoryID IsNot Nothing Then Response.Write(oCategory.ImagePath1) Else Response.Write("")%>" alt="..." style="<% if categoryid isnot nothing andalso ocategory.imagepath1 = "" then response.write("display:none;")%><%if categoryid is nothing then response.write("display:none;")%>max-height: 400px; box-shadow: 0 0 30px black; margin-top: 20px;" class="rounded10" />
                                    <div class="caption">
                                        <p>
                                            <input type="file" name="file_upload" id="imgUpload1" class="btn btn-primary" />
                                            <%If CategoryID IsNot Nothing AndAlso oCategory.ImagePath1 IsNot Nothing Then%>
                                            <div style="margin: auto; text-align: center; margin-top: 10px;">
                                                <asp:Button ID="btnRemoveImg1" runat="server" Style="" CssClass="btn btn-sm btn-danger" Text="Delete This File" OnClientClick="if (!confirm('Are you sure you want delete this Image?')) return false;" /></div>
                                            <%End If%>
                                        </p>
                                    </div>
                                </div>
                                <asp:TextBox runat="server" ID="txtImage1" CssClass="form-control" ClientIDMode="static" Visible="true" Style="display: none;" />
                            </div>
                            <div style="clear: both; height: 20px;"></div>
                            <div class="formRow">
                                <label>Image #2</label>
                                <div class="thumbnail" style="padding-top: 10px;">
                                    <img id="Image2" src="<% If CategoryID IsNot Nothing Then Response.Write(oCategory.ImagePath2) Else Response.Write("")%>" alt="..." style="<% if categoryid isnot nothing andalso ocategory.imagepath2 = "" then response.write("display:none;")%><%if categoryid is nothing then response.write("display:none;")%>max-height: 400px; box-shadow: 0 0 30px black; margin-top: 20px;" class="rounded10" />
                                    <div class="caption">
                                        <p>
                                            <input type="file" name="file_upload" id="imgUpload2" class="btn btn-primary" />
                                            <%If CategoryID IsNot Nothing AndAlso oCategory.ImagePath2 IsNot Nothing Then%>
                                            <div style="margin: auto; text-align: center; margin-top: 10px;">
                                                <asp:Button ID="btnRemoveImg2" runat="server" Style="" CssClass="btn btn-sm btn-danger" Text="Delete This File" OnClientClick="if (!confirm('Are you sure you want delete this Image?')) return false;" /></div>
                                    <%End If%>
                                        </p>
                                </div>
                            </div>
                            <asp:TextBox runat="server" ID="txtImage2" CssClass="form-control" ClientIDMode="static" Visible="true" Style="display: none;" />
                        </div>
                        <div style="clear: both; height: 20px;"></div>
                        <div class="formRow">
                            <label>Image #3</label>
                            <div class="thumbnail" style="padding-top: 10px;">
                                <img id="Image3" src="<% If CategoryID IsNot Nothing Then Response.Write(oCategory.ImagePath3) Else Response.Write("")%>" alt="..." style="<% if categoryid isnot nothing andalso ocategory.imagepath3 = "" then response.write("display:none;")%><%if categoryid is nothing then response.write("display:none;")%>max-height: 400px; box-shadow: 0 0 30px black; margin-top: 20px;" class="rounded10" />
                                <div class="caption">
                                    <p>
                                        <input type="file" name="file_upload" id="imgUpload3" class="btn btn-primary" />
                                        <%If CategoryID IsNot Nothing AndAlso oCategory.ImagePath3 IsNot Nothing Then%>
                                        <div style="margin: auto; text-align: center; margin-top: 10px;">
                                            <asp:Button ID="btnRemoveImg3" runat="server" Style="" CssClass="btn btn-sm btn-danger" Text="Delete This File" OnClientClick="if (!confirm('Are you sure you want delete this Image?')) return false;" /></div>
                                <%End If%>
                                        </p>
                            </div>
                        </div>
                        <asp:TextBox runat="server" ID="txtImage3" CssClass="form-control" ClientIDMode="static" Visible="true" Style="display: none;" />
                    </div>
                    <div style="clear: both; height: 20px;"></div>
                    <div class="formRow">
                        <label>Image #4</label>
                        <div class="thumbnail" style="padding-top: 10px;">
                            <img id="Image4" src="<% If CategoryID IsNot Nothing Then Response.Write(oCategory.ImagePath4) Else Response.Write("")%>" alt="..." style="<% if categoryid isnot nothing andalso ocategory.imagepath4 = "" then response.write("display:none;")%><%if categoryid is nothing then response.write("display:none;")%>max-height: 400px; box-shadow: 0 0 30px black; margin-top: 20px;" class="rounded10" />
                            <div class="caption">
                                <p>
                                    <input type="file" name="file_upload" id="imgUpload4" class="btn btn-primary" />
                                    <%If CategoryID IsNot Nothing AndAlso oCategory.ImagePath4 IsNot Nothing Then%>
                                    <div style="margin: auto; text-align: center; margin-top: 10px;">
                                        <asp:Button ID="btnRemoveImg4" runat="server" Style="" CssClass="btn btn-sm btn-danger" Text="Delete This File" OnClientClick="if (!confirm('Are you sure you want delete this Image?')) return false;" /></div>
                            <%End If%>
                                        </p>
                        </div>
                    </div>
                    <asp:TextBox runat="server" ID="txtImage4" CssClass="form-control" ClientIDMode="static" Visible="true" Style="display: none;" />
                </div>
            </div>
            <div style="clear: both; height: 20px;"></div>
        </div>
    </div>
    </div>
            <div style="clear: both; height: 20px;"></div>
    <div>
        <div style="float: left;">
            <div class="btn btn-warning" id="cancelBtn">Cancel</div>
            <script>
                $("#cancelBtn").click(function () { window.location.replace("categories.aspx"); return false; });
            </script>
        </div>
        <div style="float: right;">
            <asp:Button runat="server" ID="btnSave" Text="Save" CssClass="btn btn-primary" CausesValidation="true" ValidationGroup="vInformation" />
            <%If CategoryID IsNot Nothing Then%>
            <asp:Button runat="server" ID="btnDelete" Text="Delete" CssClass="btn btn-danger" Visible="true" />
            <%End If%>
        </div>
    </div>

    </div>
    </div>

</asp:Content>
