export const inlineHighlightPlugin = (md) => {
    const codeRender = md.renderer.rules.code_inline
    md.renderer.rules.code_inline = (...args) => {
        const [tokens, idx, options] = args
        const token = tokens[idx]
        if (token.attrs == null) {
            return codeRender(...args)
        } else {
            const lang = token.attrs[0][0]
            if (options.highlight) {
                const htmlStr = options.highlight(token.content, lang, '')
                return htmlStr.replace(/^<pre class="/, '<span class="inline-code-highlight ').replace(/<\/pre>$/, "</span>")
            } else {
                return codeRender(...args)
            }
        }
    }
}