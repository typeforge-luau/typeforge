use std::{fs, path::Path};

use full_moon::{ast::{luau::ExportedTypeFunction, Stmt}, node::Node, parse, tokenizer::{TokenKind, TokenType}};
use guarded::guarded_unwrap;

use convert_case::{Case, Casing};

mod lex_doc_comment;
use lex_doc_comment::DocCommentLexer;

mod parse_doc_comment;
use parse_doc_comment::parse_doc_comment;

const INIT_CONTENT: &str = include_str!("../../../src/init.luau");

const OUTPUT_PATH_STR: &str = "../../docs/site/docs";

fn parse_exported_type_func(output_path: &Path, type_func: &ExportedTypeFunction) {
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

    let output_path_for_category = output_path.join(category);
    let _ = fs::create_dir_all(&output_path_for_category);

    let _ = fs::write(output_path_for_category.join(format!("{}.md", type_func_name.to_case(Case::Snake))), parsed);
}

fn main() {
    let output_path = Path::new(OUTPUT_PATH_STR);

    if output_path.is_dir() {
        let _ = fs::remove_dir_all(output_path);
    }
    let _ = fs::create_dir_all(output_path);

    let ast = parse(INIT_CONTENT)
        .expect("Could not parse init.luau!");

    for statement in ast.nodes().stmts() {
        match statement {
            Stmt::ExportedTypeFunction(type_func) => parse_exported_type_func(output_path, type_func),
            _ => continue
        };
    }
}
