( function( $ ){

	$( ".data-api-access-table" ).each( function(){
		var $table = $( this )
		  , toggle;


		toggle = function( e ) {
			var $cb = $( this )
			  , $tr = $cb.parents( "tr:first" )
			  , topRow = $tr.hasClass( "all" )
			  , checked = $cb.prop( "checked" )
			  , subj = $cb.data( "subj" )
			  , cat = $cb.data( "cat" )
			  , notCheckedInRow
			  , notCheckedInCol;

			if ( !checked && !( topRow && subj=="all" ) ) {
				$table.find( "tr.all input[data-cat='" + cat + "'][data-subj='all']" ).prop( "checked", false );
			}

			if ( topRow ) {
				if ( subj == "all" ) {
					$table.find( "input[data-cat='" + cat + "']" ).prop( "checked", checked );
				} else {
					$table.find( "input[data-cat='" + cat + "'][data-subj='" + subj + "']" ).prop( "checked", checked );
				}
			} else {
				if ( subj == "all" ) {
					$tr.find( "input[data-cat='" + cat + "']" ).prop( "checked", checked );
				} else if ( !checked ) {
					$tr.find( "input[data-cat='" + cat + "'][data-subj='all']" ).prop( "checked", checked );
					$table.find( "tr.all input[data-cat='" + cat + "'][data-subj='" + subj + "']" ).prop( "checked", checked );
				}
			}

			notCheckedInRow = $tr.find( "input[data-cat='" + cat + "'][data-subj!='all']:not(:checked)" ).length;
			notCheckedInCol = $table.find( "tr.entity input[data-cat='" + cat + "'][data-subj='" + subj + "']:not(:checked)" ).length;

			if ( notCheckedInRow == 0 ) {
				$tr.find( "input[data-cat='" + cat + "'][data-subj='all']" ).prop( "checked", true );
			}


			if ( notCheckedInCol == 0 ) {
				$table.find( "tr.all input[data-cat='" + cat + "'][data-subj='" + subj + "']" ).prop( "checked", true );

				notCheckedInRow = $table.find( "tr.all input[data-cat='" + cat + "'][data-subj!='all']:not(:checked)" ).length;
				if ( notCheckedInRow == 0 ) {
					$table.find( "tr.all input[data-cat='" + cat + "'][data-subj='all']" ).prop( "checked", true );
				}
			}
		}

		$table.on( "click", "input[type=checkbox]", toggle );
	} );

} )( presideJQuery );