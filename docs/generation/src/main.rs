use std::{collections::HashMap, fs, path::Path};

use full_moon::{ast::{luau::ExportedTypeFunction, Stmt}, node::Node, parse, tokenizer::{TokenKind, TokenType}};
use guarded::guarded_unwrap;

mod lex_doc_comment;
use lex_doc_comment::DocCommentLexer;

mod parse_doc_comment;
use parse_doc_comment::parse_doc_comment;
use unindent::Unindent;

const INIT_CONTENT: &str = include_str!("../../../src/init.luau");

const OUTPUT_PATH_STR: &str = "../../docs/site/docs";

fn parse_exported_type_func(
    files: &mut HashMap<String, String>,
    type_func: &ExportedTypeFunction
) {
    let first_token = type_func.export_token();

    let doc_comment = guarded_unwrap!(
        first_token.leading_trivia()
        .filter(|x| matches!(x.token_kind(), TokenKind::MultiLineComment))
        .next(), return
    );

    let doc_comment_string = match doc_comment.token_type() {
        TokenType::MultiLineComment { blocks, comment } => {
            if blocks != &1 { return }
            comment.to_string()
        },
        _ => return
    } + "]=]";

    let type_func_name = type_func.type_function().function_name().to_string();

    let mut lexer = DocCommentLexer::new(&doc_comment_string);
    let (parsed, category) = parse_doc_comment(&mut lexer, &type_func_name, type_func.range().unwrap());

    files.entry(category)
        .and_modify(|f| f.push_str(&format!("\n\n- - -\n\n{}", parsed)))
        .or_insert(parsed);
}

fn main() {
    let mut files: HashMap<String, String> = HashMap::new();

    let output_path = Path::new(OUTPUT_PATH_STR);

    if output_path.is_dir() {
        let _ = fs::remove_dir_all(output_path);
    }
    let _ = fs::create_dir_all(output_path);

    let ast = parse(INIT_CONTENT)
        .expect("Could not parse init.luau!");

    for statement in ast.nodes().stmts() {
        match statement {
            Stmt::ExportedTypeFunction(type_func) => {
                parse_exported_type_func(&mut files, type_func)
            }
            _ => continue
        };
    }

    for (category, file_content) in files {
        let _ = fs::write(output_path.join(format!("{}.md", category)), file_content);
    }

    let _ = fs::write(output_path.join("index.md"), 
    "---
        title: Redirecting...
        ---

        <script setup>
        if (typeof window !== 'undefined') {
            window.location.replace('/docs/core/')
        }
        </script>

        <p>Redirecting you to the core docs...</p>".unindent()
    );
}
