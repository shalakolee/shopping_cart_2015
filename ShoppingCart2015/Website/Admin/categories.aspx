<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Admin/admin.Master" CodeBehind="categories.aspx.vb" Inherits="Website.AdminCategories" %>
<asp:Content ID="Content1" ContentPlaceHolderID="headContent" runat="server">
    <link href="../scripts/fancybox/jquery.fancybox.css" rel="stylesheet" />
    <script src="../scripts/fancybox/jquery.fancybox.js"></script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="bodyContent" runat="server">
    <script>
        $(document).ready(function () {
            $('#sidemenu-contentmanagement').addClass("active");
            $('#sidemenu-contentmanagement').find("ul").addClass("in");
            $('#sidemenu-contentmanagement').find("ul").find("li:nth-child(1)").css('background-color', '#EEEEEE');

            $(".fancybox").fancybox();

            $("#btnAddNewCategory").click(function () {
                window.location.href ="category.aspx";
            });
        });
    </script>
                <div class="row">
                    <div class="col-lg-12">
                        <h1 class="page-header">Category Management</h1>
                    </div>
                    <!-- /.col-lg-12 -->
                </div>

        <div class="panel panel-default">
        <div class="panel-heading">
            <i class="fa fa-folder-open fa-fw" style="font-size:20px;"></i> Category Management <span style="float:right;margin-top:-4px;" class="btn btn-success btn-sm" id="btnAddNewCategory"><i class="fa fa-plus-square fa-fw" style="font-size:14px;"></i> Add New Category</span>
        </div>
        <div class="panel-body" style="text-align: left;">
            <asp:ScriptManager ID="sm1" runat="server"></asp:ScriptManager>
        </div>
        <asp:UpdatePanel ID="up1" runat="server" RenderMode="block">
            <ContentTemplate>
                <div class="panel panel-default" style="margin: auto;margin-top:-20px;margin-left:15px;margin-right:15px;margin-bottom:15px;">
                    <div class="panel-heading" style="text-align:left;">Paging and Filters</div>
                    <div class="panel-body">
                        <div style="float:left;">
                            <div class="right">
                                <asp:HiddenField ID="hdnCurrentPage" runat="server" Value="1" />
                                Results per page:&nbsp;<asp:DropDownList ID="ddlPager" runat="server" AutoPostBack="True" >
                                    <asp:ListItem Value="0" Selected="True">All</asp:ListItem>
                                    <asp:ListItem Value="8">8</asp:ListItem>
                                    <asp:ListItem Value="12">12</asp:ListItem>
                                    <asp:ListItem Value="24">24</asp:ListItem>
                                </asp:DropDownList>
                            </div>
                            <div class="left">
                                <asp:LinkButton ID="lnkPrev" runat="server">&laquo; Prev</asp:LinkButton>&nbsp;&nbsp;
                            <asp:Label ID="lblPage" runat="server"></asp:Label>
                                &nbsp;&nbsp;<asp:LinkButton ID="lnkNext" runat="server">Next &raquo;</asp:LinkButton>
                            </div>
                        </div>
                        <div style="float:right;">
                            <label>Status</label>
                            <asp:DropDownList runat="server" ID="cboStatus" AutoPostBack="true">
                                <asp:ListItem>[All]</asp:ListItem>
                                <asp:ListItem Selected="true" class="text-success">Active</asp:ListItem>
                                <asp:ListItem class="text-warning">Inactive</asp:ListItem>
                            </asp:DropDownList>
                        </div>

                    </div>
                </div>
                <asp:Repeater runat="server" ID="rptOffices">
                    <HeaderTemplate>
                        <table class="table table-striped">
                            <tr>
                                <th style="width:100px;text-align:left;">Image</th>
                                <th>Category Name</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td>
                                <%#GetImage(Eval("CategoryID"),Eval("imagepath1")) %>
                            </td>
                            <td align="left">
                                <%#Eval("categoryName")%>
                            </td>
                            <td class="<%#IIf(Eval("Status") = "Active", "text-success", IIf(Eval("Status") = "Inactive", "text-warning", "text-danger"))%>"><%#Eval("Status")%></td>
                            <td align="left">
                                <a href="category.aspx?id=<%#Eval("CategoryID")%>"><span class="glyphicon glyphicon-edit"></span>Edit</a> &nbsp; 
                                <a href="action.aspx?action=deletecategory&id=<%#Eval("categoryid") %>&returl=<%=Request.RawUrl%>" class="text-danger"><span class="fa fa-trash-o fa-fw"></span>Delete</a>
                            </td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate>
                        </table>
                    </FooterTemplate>

                </asp:Repeater>


            </ContentTemplate>
        </asp:UpdatePanel>

    </div>


</asp:Content>
