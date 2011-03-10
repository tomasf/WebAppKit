<h1><%print exception name></h1>

<%print exception reason>

<h2>Backtrace</h2>
<pre>
<%print exception callStackSymbols componentsJoinedByString:'\n'>
</pre>
Break on objc_exception_throw to debug.