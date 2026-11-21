//
//  Plugin+Apple+IconPatch.swift
//

import Foundation

extension PluginApple {
    /// Workspace-relative package holding the exported patch.
    static let mixedAppIconsPatchDirectory = "tools/rules_apple"

    /// rules_apple 5.4.0 rejects `app_icons` that combine Icon Composer `.icon`
    /// bundles with legacy `.appiconset` files, even when `primary_app_icon`
    /// names the primary icon. Xcode compiles both into the same asset catalog:
    /// `.icon` and legacy alternate icons reach actool together for pre-26 targets.
    /// The consuming wrapper materializes Icon Composer bundles as regular files
    /// within the same action; a producer copy alone is symlinked by the next sandbox.
    static let mixedAppIconsPatch = #"""
    --- a/apple/internal/resource_actions/actool.bzl
    +++ b/apple/internal/resource_actions/actool.bzl
    @@ -165,6 +165,7 @@
             icon_bundle_files,
             icon_files,
             minimum_os_version,
    +        primary_icon_name,
             xcode_config):
         """Validates that the asset files contain only standard app icon sets."""
     
    @@ -173,6 +174,10 @@
             apple_common.dotted_version("26.0")
         )
     
    +    # An explicit primary icon allows Icon Composer bundles to be paired with legacy .appiconset
    +    # files, which actool uses for releases prior to 26.
    +    allow_mixed_icons = bool(primary_icon_name) and bool(icon_bundle_files) and not min_os_version_26_or_later
    +
         if min_os_version_26_or_later and icon_files:
             fail("""
     Legacy .appiconset files should not be used on iOS/macOS/watchOS 26+.
    @@ -196,7 +201,7 @@
                 supported on Xcode 26 or later.
                 """)
     
    -        if icon_files:
    +        if icon_files and not allow_mixed_icons:
                 fail("""
                 Found .appiconset files among the assigned app_icons, which are ignored when Icon \
                 Composer .icon bundles are present.
    @@ -212,6 +217,7 @@
             asset_files,
             minimum_os_version,
             platform_type,
    +        primary_icon_name,
             product_type,
             xcode_config):
         """Returns information about the icon files in the asset files."""
    @@ -261,6 +267,7 @@
                 icon_bundle_files = icon_bundle_files,
                 icon_files = icon_files,
                 minimum_os_version = minimum_os_version,
    +            primary_icon_name = primary_icon_name,
                 xcode_config = xcode_config,
             )
         return struct(
    @@ -455,6 +462,7 @@
             asset_files = asset_files,
             minimum_os_version = minimum_os_version,
             platform_type = platform_type,
    +        primary_icon_name = primary_icon_name,
             product_type = product_type,
             xcode_config = xcode_config,
         )
    
    --- a/tools/xctoolrunner/xctoolrunner.py
    +++ b/tools/xctoolrunner/xctoolrunner.py
    @@ -37,10 +37,12 @@
     """
     
     import argparse
    +import contextlib
     import os
     import re
     import shutil
     import sys
    +import tempfile
     
     from tools.wrapper_common import execute
     
    @@ -306,14 +308,29 @@
       return (tool_exit_status, "".join(output), "".join(errors_collected))
     
     
    +@contextlib.contextmanager
    +def _materialized_icon_bundles(toolargs):
    +  """Give actool regular Icon Composer files within this consuming action."""
    +  icons = [(index, path) for index, path in enumerate(toolargs)
    +           if os.path.isabs(path) and path.endswith(".icon") and os.path.isdir(path)]
    +  if not icons:
    +    yield toolargs
    +    return
    +  with tempfile.TemporaryDirectory(prefix="bazelize-actool-icons-") as root:
    +    arguments = list(toolargs)
    +    for index, source in icons:
    +      destination = os.path.join(root, str(index), os.path.basename(source))
    +      shutil.copytree(source, destination, symlinks=False)
    +      arguments[index] = destination
    +    yield arguments
    +
    +
     def actool(_, toolargs):
       """Assemble the call to "xcrun actool"."""
       xcrunargs = ["xcrun", "actool"]
     
       _apply_realpath(toolargs)
     
    -  xcrunargs += toolargs
    -
       # The argument coming after "--compile" is the output directory. "actool"
       # expects an directory to exist at that path. Create an empty directory there
       # if one doesn't exist yet.
    @@ -334,7 +351,9 @@
       # helps.
       # Yes, IBTOOL appears to be correct here due to "actool" and "ibtool" being
       # based on the same codebase.
    -  return _execute_and_filter_with_retry(xcrunargs=xcrunargs, filtering=actool_filtering)
    +  with _materialized_icon_bundles(toolargs) as arguments:
    +    return _execute_and_filter_with_retry(
    +        xcrunargs=xcrunargs + arguments, filtering=actool_filtering)
     
     
     def coremlc(_, toolargs):
    
    """# + "\n"
}
