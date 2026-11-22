#!/bin/bash
# Project-local environment for a HyperFrames film. Source it before running any tool:
#   source video/source/bin/env.sh
# It expects to live at <project>/video/source/bin/env.sh.
# Everything the tools download or cache stays under video/.home; nothing is written to the
# user's home folder, nothing is reported, and no sign-in is used. Works in bash and zsh.
if [ -n "${BASH_SOURCE:-}" ]; then _video_env_src="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then eval '_video_env_src="${(%):-%x}"'
else _video_env_src="$0"; fi
VIDEO_DIR="$(cd "$(dirname "$_video_env_src")/../.." && pwd)"
unset _video_env_src
export VIDEO_DIR
export REAL_HOME="${REAL_HOME:-$HOME}"
export HOME="$VIDEO_DIR/.home"
export HYPERFRAMES_NO_TELEMETRY=1
export HYPERFRAMES_NO_UPDATE_CHECK=1
export HYPERFRAMES_SKIP_SKILLS=1
export DO_NOT_TRACK=1
export npm_config_update_notifier=false
export HYPERFRAMES_FFMPEG_PATH="$VIDEO_DIR/source/node_modules/ffmpeg-static/ffmpeg"
export HYPERFRAMES_FFPROBE_PATH="$VIDEO_DIR/source/node_modules/ffprobe-static/bin/darwin/arm64/ffprobe"
export FFMPEG="$HYPERFRAMES_FFMPEG_PATH"
export FFPROBE="$HYPERFRAMES_FFPROBE_PATH"
# local voice (Kokoro) and the music script run on the project's own Python
export HYPERFRAMES_PYTHON="$VIDEO_DIR/.home/venv/bin/python"
