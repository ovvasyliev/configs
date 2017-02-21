<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:template match="testsuites">
		<div>
			<div>
			<xsl:for-each select="testsuite">
				<h3> Test suite: <xsl:value-of select="@name" /> </h3>
				<table border="1">
					<tr bgcolor="#9acd32">
						<th> Tests </th>
						<th> failures </th>
						<th> disabled </th>
						<th> errors </th>
						<th> time </th>
					</tr>
					<tr>
						<td align="center">
							<xsl:value-of select="@tests" />
						</td>
						<td align="center">
							<xsl:value-of select="@failures" />
						</td>
						<td align="center">
							<xsl:value-of select="@disabled" />
						</td>
						<td align="center">
							<xsl:value-of select="@errors" />
						</td>
						<td align="center">
							<xsl:value-of select="@time" />
						</td>
					</tr>
				</table>
				<h4>Test cases:</h4>
				<style>
					.TFtable
					{
						width:900px; 
						border-collapse:collapse; 
					}
					.TFtable td
					{ 
						padding:7px; border:#4e95f4 1px solid;
					}
					/* provide some minimal visual accomodation for IE8 and below */
					.TFtable tr
					{
						background: #b8d1f3;
					}
					/*  Define the background color for all the ODD background rows  */
					.TFtable tr:nth-child(odd)
					{ 
						background: #b8d1f3;
					}
					/*  Define the background color for all the EVEN background rows  */
					.TFtable tr:nth-child(even)
					{
						background: #dae5f4;
					}
				</style>
				<table class="TFtable">
					<tr bgcolor="#9acd32" style="border:#4e95f4 1px solid;">
						<th style="border:#4e95f4 1px solid;"> Test case </th>
						<th> Run time </th>
					</tr>
					<xsl:for-each select="testcase">
						<tr>
							<td align="left" style="padding-left: 10px;">
								<xsl:value-of select="@name" />
							</td>
							<td align="center">
								<xsl:value-of select="@time" />
							</td>
						</tr>
					</xsl:for-each>
				</table>
			</xsl:for-each>
			</div>
		</div>
	</xsl:template>
</xsl:stylesheet>