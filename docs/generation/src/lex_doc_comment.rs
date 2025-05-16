use logos::Logos;

#[derive(Logos, Debug, PartialEq)]
pub enum DocCommentTagToken {
    #[token("@param")]
    ParamTag,

    #[token("@example")]
    ExampleTag,

    #[token("@category")]
    CategoryTag,

    #[token("]=]")]
    EndTag,
}

pub struct DocCommentLexer<'a> {
    pub lexer: logos::Lexer<'a, DocCommentTagToken>,
    tag_token: Option<DocCommentTagToken>,
}

#[derive(Debug)]
pub struct DocCommentItem {
    pub tag_token: Option<DocCommentTagToken>,
    pub body: Option<String>
}

impl<'a> DocCommentLexer<'a>  {
    pub fn new(content: &'a str) -> Self {
        let mut lexer = DocCommentTagToken::lexer(content);

        let tag_token = match lexer.next() {
            Some(tag_token) => match tag_token {
                Ok(tag_token) => Some(tag_token),
                Err(_) => None,
            },
            None => None,
        };

        Self {
            lexer,
            tag_token
        }
    }
}

impl<'a> Iterator for DocCommentLexer<'a> {
    type Item = DocCommentItem;

    fn next(&mut self) -> Option<Self::Item> {
        let lexer = &mut self.lexer;

        let tag_token = self.tag_token.take();

        // Gets the initial body character.
        let mut body = match lexer.next() {
            Some(tag_token) => match tag_token {
                Ok(tag_token) => {
                    return Some(DocCommentItem { tag_token: Some(tag_token), body: None })
                },
                Err(_) => lexer.slice().to_string(),
            },
            None => return if tag_token.is_some() { Some(DocCommentItem { tag_token, body: None }) } else { None },
        };

        // Loops through the tokens until it finds a tag token.
        loop {
            match lexer.next() {
                Some(next_tag_token) => match next_tag_token {
                    Ok(next_tag_token) => {
                        if next_tag_token != DocCommentTagToken::EndTag {
                            self.tag_token = Some(next_tag_token);
                        }
                        return Some(DocCommentItem { tag_token, body: Some(body.trim().to_string()) })
                    },
                    Err(_) => {
                        body += lexer.slice()
                    },
                },
                None => {
                    return Some(DocCommentItem { tag_token, body: Some(body.trim().to_string()) })
                },
            };
        }
    }
}