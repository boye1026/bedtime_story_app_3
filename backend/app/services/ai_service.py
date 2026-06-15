"""
閫氫箟鍗冮棶 AI 鏈嶅姟妯″潡
浣跨敤 OpenAI SDK 杩炴帴閫氫箟鍗冮棶 API锛屾彁渚涙晠浜嬬敓鎴愯兘鍔?鏀寔娴佸紡鍜岄潪娴佸紡鍝嶅簲
"""

import logging
from openai import OpenAI, APITimeoutError, AuthenticationError, APIError

logger = logging.getLogger(__name__)


class AIService:
    """
    閫氫箟鍗冮棶 AI 鏈嶅姟绫?    灏佽涓庨€氫箟鍗冮棶 API 鐨勪氦浜掗€昏緫
    """

    def __init__(self, app=None):
        """
        鍒濆鍖?AI 鏈嶅姟

        Args:
            app: Flask 搴旂敤瀹炰緥锛堝彲閫夛紝鐢ㄤ簬寤惰繜鍒濆鍖栵級
        """
        self.client = None
        self.model = None
        self.timeout = 60

        if app is not None:
            self.init_app(app)


# 鍒涘缓鍏ㄥ眬 AI 鏈嶅姟瀹炰緥
ai_service = AIService()
    def init_app(self, app):
        """
        浣跨敤 Flask 搴旂敤閰嶇疆鍒濆鍖?AI 鏈嶅姟

        Args:
            app: Flask 搴旂敤瀹炰緥
        """
        api_key = app.config.get("QWEN_API_KEY", "")
        api_base = app.config.get("QWEN_API_BASE", "https://dashscope.aliyuncs.com/compatible-mode/v1")
        self.model = app.config.get("QWEN_MODEL", "qwen-turbo")
        self.timeout = app.config.get("QWEN_TIMEOUT", 60)

        if not api_key:
            logger.warning("QWEN_API_KEY 鏈厤缃紝AI 鏈嶅姟灏嗘棤娉曟甯稿伐浣?)

        # 浣跨敤 OpenAI SDK 鍒濆鍖栧鎴风锛堥€氫箟鍗冮棶鍏煎妯″紡锛?        self.client = OpenAI(
            api_key=api_key,
            base_url=api_base,
            timeout=self.timeout,
        )

        logger.info(f"AI 鏈嶅姟鍒濆鍖栧畬鎴愶紝妯″瀷: {self.model}")

    def generate_story(self, system_prompt, user_prompt, stream=False):
        """
        璋冪敤閫氫箟鍗冮棶 API 鐢熸垚鏁呬簨

        Args:
            system_prompt (str): 绯荤粺鎻愮ず璇嶏紝瀹氫箟 AI 鐨勮鑹插拰琛屼负
            user_prompt (str): 鐢ㄦ埛鎻愮ず璇嶏紝鍖呭惈鏁呬簨鐢熸垚鐨勫叿浣撹姹?            stream (bool): 鏄惁浣跨敤娴佸紡鍝嶅簲锛岄粯璁や负 False

        Returns:
            str: 鐢熸垚鐨勬晠浜嬪唴瀹癸紙闈炴祦寮忔ā寮忥級
            generator: 娴佸紡鍝嶅簲鐢熸垚鍣紙娴佸紡妯″紡锛?
        Raises:
            AIServiceError: AI 鏈嶅姟鐩稿叧閿欒
        """
        if self.client is None:
            raise AIServiceError("AI 鏈嶅姟鏈垵濮嬪寲锛岃妫€鏌ラ厤缃?)

        try:
            if stream:
                return self._generate_stream(system_prompt, user_prompt)
            else:
                return self._generate_sync(system_prompt, user_prompt)

        except APITimeoutError:
            logger.error("AI API 璇锋眰瓒呮椂")
            raise AIServiceError("AI 鐢熸垚瓒呮椂锛岃绋嶅悗閲嶈瘯")

        except AuthenticationError:
            logger.error("AI API 瀵嗛挜鏃犳晥")
            raise AIServiceError("AI 鏈嶅姟璁よ瘉澶辫触锛岃妫€鏌?API 瀵嗛挜閰嶇疆")

        except APIError as e:
            logger.error(f"AI API 閿欒: {str(e)}")
            # 妫€鏌ユ槸鍚︿负鍐呭瀹夊叏鎷︽埅
            error_msg = str(e).lower()
            if "content" in error_msg and "safety" in error_msg:
                raise AIServiceError("鏁呬簨鍐呭鏈€氳繃瀹夊叏瀹℃牳锛岃璋冩暣鐢熸垚瑕佹眰鍚庨噸璇?)
            raise AIServiceError(f"AI 鏈嶅姟寮傚父: {str(e)}")

        except Exception as e:
            logger.error(f"AI 鐢熸垚鏈煡閿欒: {str(e)}")
            raise AIServiceError(f"鏁呬簨鐢熸垚澶辫触: {str(e)}")

    def _generate_sync(self, system_prompt, user_prompt):
        """
        闈炴祦寮忕敓鎴愭晠浜?
        Args:
            system_prompt (str): 绯荤粺鎻愮ず璇?            user_prompt (str): 鐢ㄦ埛鎻愮ず璇?
        Returns:
            str: 鐢熸垚鐨勬晠浜嬫枃鏈?        """
        logger.info("寮€濮嬮潪娴佸紡鏁呬簨鐢熸垚...")

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.8,      # 閫傚害鐨勫垱閫犳€?            max_tokens=2000,        # 鏈€澶х敓鎴愰暱搴?            top_p=0.9,
            stream=False,
        )

        content = response.choices[0].message.content.strip()
        logger.info(f"鏁呬簨鐢熸垚瀹屾垚锛岄暱搴? {len(content)} 瀛楃")

        return content

    def _generate_stream(self, system_prompt, user_prompt):
        """
        娴佸紡鐢熸垚鏁呬簨

        Args:
            system_prompt (str): 绯荤粺鎻愮ず璇?            user_prompt (str): 鐢ㄦ埛鎻愮ず璇?
        Yields:
            str: 閫愭鐢熸垚鐨勬晠浜嬫枃鏈?        """
        logger.info("寮€濮嬫祦寮忔晠浜嬬敓鎴?..")

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.8,
            max_tokens=2000,
            top_p=0.9,
            stream=True,
        )

        full_content = ""
        for chunk in response:
            if chunk.choices and chunk.choices[0].delta.content:
                delta = chunk.choices[0].delta.content
                full_content += delta
                yield delta

        logger.info(f"娴佸紡鏁呬簨鐢熸垚瀹屾垚锛屾€婚暱搴? {len(full_content)} 瀛楃")


class AIServiceError(Exception):
    """AI 鏈嶅姟鑷畾涔夊紓甯?""
    pass

