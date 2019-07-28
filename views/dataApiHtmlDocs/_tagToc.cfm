<cfscript>
	tag = args.tag ?: {};
	spec = args.spec ?: {};
	paths = spec.paths ?: {};
	headerId = "section/#slugify( tag.name ?: '' )#";
</cfscript>

<cfoutput>
	<li data-item-id="#headerId#">
		<label role="menuitem" type="tag" class="-depth1">
			<a href="###headerId#" title="#HtmlEditFormat( tag.name ?: '' )#">#( tag.name ?: '' )#</a>
		</label>
		<cfif IsFalse( tag[ "x-traitTag" ] ?: "" )>
			<ul>
				<cfloop collection="#paths#" item="path" index="pathName">
					<cfset pathFound = false />
					<cfloop collection="#path#" item="method" index="methodName">
						<cfif ArrayFindNoCase( method.tags ?: [], tag.name ?: "" )>
							<cfset methodHeaderId = headerId & "#pathName#~#methodName#" />
							<li data-item-id="#methodHeaderId#">
								<label role="menuitem">
									<span class="operation-type #LCase( methodName )#" type="#LCase( methodName )#">#LCase( methodName == "delete" ? "del" : methodName )#</span>
									<a href="###methodHeaderId#">#pathName#</a>
								</label>
							</li>
						</cfif>
					</cfloop>
				</cfloop>
			</ul>
		</cfif>
	</li>
</cfoutput>