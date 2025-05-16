use full_moon::tokenizer::Position;
use guarded::guarded_unwrap;
use unindent::Unindent;

use crate::lex_doc_comment::{DocCommentLexer, DocCommentTagToken};

const GITHUB_URL_PREFIX: &str = "https://github.com/typeforge-luau/typeforge/blob/main/src/init.luau";

fn github_url_for_range(range: (Position, Position)) -> String {
    format!("{}#L{}-L{}", GITHUB_URL_PREFIX, range.0.line(), range.1.line())
}

pub fn parse_doc_comment(
    lexer: &mut DocCommentLexer<'_>,
    type_func_name: &str,
    type_func_range: (Position, Position)
) -> (String, String) {
    let description;
    let mut category: String = "Miscellaneous".into();

    let mut params = String::new();
    let mut examples = String::new();
    let mut examples_count = 0;
    
    let mut item = guarded_unwrap!(lexer.next(), return (String::new(), category.to_lowercase()));
    let item_tag_token = item.tag_token;
    match item_tag_token {
        None => if let Some(body) = item.body.take() {
            description = body.unindent() + &format!(" [View On Github]({})", github_url_for_range(type_func_range))
        } else {
            description = String::new()
        },

        Some(item_tag_token) => {
            description = String::new();

            if let Some(body) = item.body.take() {
                match item_tag_token {
                    DocCommentTagToken::ParamTag => {
                        let (param_name, body) = body.split_once(" ").unwrap();
                        let (param_type, param_description) = body.split_once("--").unwrap();
    
                        params += &format!("| {} | {} | {} |\n", param_name, param_type.trim(), param_description.trim());
                    },
    
                    DocCommentTagToken::ExampleTag => {
                        examples_count += 1;
                        examples += &format!("```luau\n{}\n```\n", body.unindent())
                    },

                    DocCommentTagToken::CategoryTag => {
                        category = body.trim().into()
                    }
    
                    _ => unimplemented!()
                }
            }
        }
    }

    loop {
        let mut item = guarded_unwrap!(lexer.next(), break);
        match item.tag_token {
            Some(item_tag_token) => if let Some(body) = item.body.take() {
                match item_tag_token {
                    DocCommentTagToken::ParamTag => {
                        let (param_name, body) = body.split_once(" ").unwrap();
                        let (param_type, param_description) = body.split_once("--").unwrap();

                        params += &format!("| {} | {} | {} |\n", param_name, param_type.trim(), param_description.trim());
                    },

                    DocCommentTagToken::ExampleTag => {
                        examples_count += 1;
                        examples += &format!("```luau\n{}\n```\n", body.unindent())
                    },

                    DocCommentTagToken::CategoryTag => {
                        category = body.trim().into()
                    }

                    DocCommentTagToken::EndTag => unimplemented!()
                }
            },

            None => {},
        }
    }

    let mut parsed = description;

    if params.len() != 0 {
        parsed += &format!("\n\n## Params\n| Name | Type | Description |\n| ---- | ---- | ----------- |\n{}", params.trim_end())
    }

    if examples_count == 1 {
        parsed += &format!("\n\n## Example\n{}", examples.trim_end())
    } else if examples_count != 0 {
        parsed += &format!("\n\n## Examples\n{}", examples.trim_end())
    }

    (format!("# {}\n{}", type_func_name, parsed), category.to_lowercase())
}