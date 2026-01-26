load("@rules_pkg//pkg/private/tar:tar.bzl", "pkg_tar")

def _flatten_squirrel_includes_impl(ctx):
    srcs = ctx.files.srcs
    flattened_files = []
    for src in srcs:
        output_file = ctx.actions.declare_file(src.basename)
        args = ctx.actions.args()
        args.add(src)
        args.add("-o", output_file)
        ctx.actions.run(
            mnemonic = "FlattenSquirrelIncludes",
            executable = ctx.executable._flatten_script,
            arguments = [args],
            inputs = [src],
            outputs = [output_file]
        )
        flattened_files.append(output_file)
    
    return DefaultInfo(
        files = depset(flattened_files),
    )
    

flatten_squirrel_includes = rule(
    implementation = _flatten_squirrel_includes_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".nut"]),
        "_flatten_script": attr.label(
            default = Label("//scripts/python:flatten_squirrel_includes"),
            executable = True,
            cfg = "exec",
        )
    }
)

def make_archive(name, srcs, extra_files):
    pkg_tar(
        name = name,
        srcs = srcs + extra_files,
        out = name + ".tar",
    )
