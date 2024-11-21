component {

	private string function default( event, rc, prc, args={} ){
		var objName = args.data ?: "";

		return Len( Trim( objName ) ) ? "#translateResource( uri="preside-objects.#objName#:title", defaultValue=objName )# (#objName#)" : "";
	}
}