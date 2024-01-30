StringBuilder str = new StringBuilder();
str.Append("<table border=`" + "1px" + "`b>");
str.Append("<tr>");
str.Append("<td><b><font face=Arial Narrow size=3>id</font></b></td>");
str.Append("<td><b><font face=Arial Narrow size=3>name</font></b></td>");
str.Append("<td><b><font face=Arial Narrow size=3>parent_id</font></b></td>");
str.Append("<td><b><font face=Arial Narrow size=3>original_id</font></b></td>");
str.Append("<td><b><font face=Arial Narrow size=3>original_parent_id</font></b></td>");
str.Append("</tr>");
foreach (AccepInfo val in listAccept)
{
    str.Append("<tr>");
    str.Append("<td><font face=Arial Narrow size=" + "14px" + ">" + val.id.ToString() + "</font></td>");
    str.Append("<td><font face=Arial Narrow size=" + "14px" + ">" + val.name.ToString() + "</font></td>");
    str.Append("<td><font face=Arial Narrow size=" + "14px" + ">" + val.parent_id.ToString() + "</font></td>");
    str.Append("<td><font face=Arial Narrow size=" + "14px" + ">" + val.original_id.ToString() + "</font></td>");
    str.Append("<td><font face=Arial Narrow size=" + "14px" + ">" + val.original_parent_id.ToString() + "</font></td>");
    str.Append("</tr>");
}
str.Append("</table>");
HttpContext.Response.Headers.Add("content-disposition", "attachment; filename=GetAPIsDataResult" + DateTime.Now.ToString("yyyy-MM-dd_hh'h'mm") + ".xls");
//this.Response.ContentType = "application/vnd.ms-excel";
this.Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
byte[] temp = System.Text.Encoding.UTF8.GetBytes(str.ToString());

return File(temp, "application/vnd.ms-excel");
//return response;