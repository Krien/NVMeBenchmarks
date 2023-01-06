import os
import subprocess
import datetime


class FioRunner:
    """Runner for fio"""

    def __init__(self, fio_path, overwrite=True):
        self.fio = fio_path
        self.preload = None
        self.overwrite = overwrite

    def LD_PRELOAD(self, preload):
        self.preload = preload

    def __generate_cmd(
        self, jobpath, outpath, fio_shell_opts=[], fio_extra_opts=[]
    ) -> str:
        extra_opts = fio_extra_opts + ["output-format=json", f"output={outpath}"]
        job_str = ""
        if self.preload != None:
            job_str += f"LD_PRELOAD={self.preload} "
        job_str += " ".join(fio_shell_opts) + " "
        job_str += f"{self.fio} "
        job_str += f"{jobpath} "
        job_str += " ".join([f"--{arg}" for arg in extra_opts])
        return job_str

    def run_job(
        self, jobpath, outpath, fio_shell_opts=[], fio_extra_opts=[], mock: bool = False
    ):
        if not self.overwrite and os.path.exists(outpath):
            print(f"Output file {outpath} already exists, enable overwrite to enable")
            return
        outdir = os.path.dirname(outpath)
        os.makedirs(outdir, exist_ok=True)
        cmd = self.__generate_cmd(jobpath, outpath, fio_shell_opts, fio_extra_opts)
        if not mock:
            subprocess.check_call(cmd, shell=True)
        else:
            with open(outpath, "w") as fi:
                fi.writelines(
                    [f"running command at {datetime.datetime.now()}" "\n", f"{cmd}"]
                )
