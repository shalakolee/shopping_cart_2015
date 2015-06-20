<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Admin/admin.Master" CodeBehind="salestax.aspx.vb" Inherits="Website.salestaxadmin" %>
<asp:Content ID="Content1" ContentPlaceHolderID="headContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="bodyContent" runat="server">
                <div class="row">
                    <div class="col-lg-12">
                        <h1 class="page-header">Sales Tax Management</h1>
                    </div>
                    <!-- /.col-lg-12 -->
                </div>
    <script>
        $(document).ready(function () {
            $('#sidemenu-configuration').addClass("active");
            $('#sidemenu-configuration').find("ul").addClass("in");
            $('#sidemenu-configuration').find("ul").find("li:nth-child(3)").css('background-color', '#EEEEEE');

        });
    </script>
            <%
            If Request("success") = "true" Then
                phSuccess.Visible = True%>
                <script>
                    $(document).ready(function () {
                        $('#asdf').delay(3200).fadeOut(1300);
                    });

                </script>
            <%
            Else
                phSuccess.Visible = False
            End If
            %>
                        <asp:PlaceHolder ID="phSuccess" runat="server" Visible="false" ClientIDMode="static">
                            <div id="asdf" class="alert alert-success" role="alert">Sales tax update was a success!</div>
                        </asp:PlaceHolder>

                        <div class="panel panel-default">
                            <div class="panel-heading">Please select states that you will charge sales tax in.</div>
                            <div class="panel-body">
                                <asp:DropDownList ID="ddlStates" runat="server" CssClass="form-control" ClientIDMode="static"></asp:DropDownList>
                                <style>
                                    .itemList-item {
                                        float:left;
                                        margin:2px;
                                    }
                                        .alert{}
                                </style>

                                <div id="itemList" style="margin-top:10px;"></div>
                                <div style="clear:both;"></div>

                                <asp:CheckBoxList ID="chklstStates" runat="server" style="display:none;" ClientIDMode="static"></asp:CheckBoxList>
                                <div style="text-align:right;">
						            <ASP:BUTTON id="btnSave" runat="server" text="Save Changes &raquo;" CssClass="btn btn-success" style="margin-top:10px;"> </ASP:BUTTON>
                                </div>
                            </div>
                        </div>
                    <script>
                    $(document).ready(function () {
                        $("#ddlStates").change(function () {

                            var name = $("#ddlStates option:selected").text().replace(/\-/g, ' ');
                            var id = $("#ddlStates option:selected").val();

                            if ($("#itemList #" + id).length) {
                                //do nothing
                            } else {
                                $("#itemList").append("<div id='" + id + "' class='itemList-item alert alert-success alert-dismissable'>" + name + "<button class='deleteBtn close ' data-dismiss='alert' aria-hidden='true'>&times;</button></div>");
                                $("#chklstStates #" + id).prop("checked", true);
                            };
                        });

                        //we need to run this once to load up and append all the categories that are previously enabled
                        <%Dim counter = 0%>
                        <%For Each item As ListItem In chklstStates.Items%>
                            <%If item.Selected = True Then%>
                               $("#itemList").append("<div id='chklstStates_<%=counter%>' class='itemList-item alert alert-success alert-dismissable'><%=item.Text%><button class='deleteBtn close ' data-dismiss='alert' aria-hidden='true'>&times;</button></div>");
                            <%end If %>
                            <%counter +=1%>
                        <%next %>

                        $("#itemList").delegate(".deleteBtn", "click", function () {

                            var id = $(this).parent().attr("id");
                            console.log(id);
                            $(this).parent().remove();
                            $("#chklstStates #" + id).prop("checked", false);
                        });

                    });
                </script>



</asp:Content>
