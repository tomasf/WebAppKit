<h1><%print exception.name.HTML></h1>

<%print exception.reason.HTML>

<h2>Backtrace</h2>
<pre>
<%print [exception.callStackSymbols componentsJoinedByString:"\n"].HTML>
</pre>
Break on objc_exception_throw to debug.