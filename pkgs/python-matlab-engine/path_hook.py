from importlib.machinery import PathFinder
import sys
import os

class CustomPathFinder(PathFinder):
    @classmethod 
    def find_spec(cls, fullname, path=None, target=None):
        spec = None
        if fullname in ["matlab", "matlab.engine"]:
            spec = PathFinder.find_spec(fullname, path, target)
            if not spec:
                return spec

            mlab_arch = "glnxa64"
            mlab_idir = os.path.expandvars("$MATLAB_INSTALL_DIR")
            mlab_engine_dir = os.path.join(mlab_idir, "extern", "engines", "python", "dist", "matlab", "engine")
            mlab_arch_path = os.path.join(mlab_engine_dir, "_arch.txt")

            if not os.path.isfile(mlab_arch_path):
                mlab_bin_dir = os.path.join(mlab_idir, "bin")
                mlab_extern_bin_dir = os.path.join(mlab_idir, "extern", "bin", mlab_arch)
                mlab_engine_dir = os.path.join(mlab_engine_dir, mlab_arch)
                try:
                    with open(mlab_arch_path, "w+") as f:
                        f.write(f"{mlab_arch}\n")
                        f.write(f"{mlab_bin_dir}\n")
                        f.write(f"{mlab_engine_dir}\n")
                        f.write(mlab_extern_bin_dir)
                except Exception as err:
                    print(f"Could not write Matlab architecture file at {matlab_dist_path}...")
                    print(err)
        return spec

sys.meta_path.insert(0, CustomPathFinder)
