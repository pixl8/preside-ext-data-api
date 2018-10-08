<cfoutput><!DOCTYPE html>
<html>
  <head>
    <title>#translateResource( "dataapi:api.title" )# #translateResource( "dataapi:api.version" )#</title>
    <!-- needed for adaptive design -->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700" rel="stylesheet">

    <link rel="icon" type="image/png" href="#args.favicon32#" sizes="32x32" />
    <link rel="icon" type="image/png" href="#args.favicon16#" sizes="16x16" />
    <!--
    ReDoc doesn't change outer page styles
    -->
    <style>
      body {
        margin: 0;
        padding: 0;
      }

      .redoc-wrap .dkuWnU,
      .sc-htpNat.dwJFae {
        color:##2679b5;
      }

      .redoc-wrap .api-info > h1 + p {
        margin-bottom: 20px;
        color: ##999;
        text-align: right;
      }

      .redoc-wrap .lmeAqe {
        color:##777;
        border-color:##777;

      }

      .sc-bwzfXH.jMSjCT path {
        fill:##2679b5;
      }

      .redoc-wrap .gkBCoe {
        display: none;
      }

      .redoc-wrap .bOgKnn,
      .redoc-wrap .fMRrIL {
        padding:10px 0;
      }

      .redoc-wrap h1 {
        border-bottom: 1px dotted ##2679b5;
      }

      .redoc-wrap .menu-content {
        padding-top : 16px;
      }

      .redoc-wrap .menu-content .idskhQ {
        border-style: none none dotted;
      }
    </style>
  </head>
  <body>
    <redoc spec-url='#args.specsEndpoint#' required-props-first="true" suppress-warnings="true"></redoc>
    <script src="#args.docsJs#"> </script>
  </body>
</html></cfoutput>