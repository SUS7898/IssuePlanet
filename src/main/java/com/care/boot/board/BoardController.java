package com.care.boot.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Controller
public class BoardController {
	@Autowired private BoardService service;
	@Autowired private HttpSession session;
	
	@RequestMapping("boardForm")
	public String boardForm(Model model,
			@RequestParam(value="currentPage", required = false)String cp) {
		service.boardForm(cp, model);
		return "board/boardForm";
	}
	
	
	@RequestMapping("boardWrite")
	public String boardWrite() {
		String sessionId = (String) session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		return "board/boardWrite";
	}
	
	@PostMapping("boardWriteProc")
	public String boardWriteProc(MultipartHttpServletRequest multi) {
		String sessionId = (String) session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		String path = service.boardWriteProc(multi);
		return path;
	}
	
	@RequestMapping("boardContent")
	public String boardContent(String no, Model model) {
		BoardDTO board = service.boardContent(no);
		if(board == null) {
			return "redirect:boardForm";
		}
		
		model.addAttribute("board", board);
		return "board/boardContent";
	}
	
	@RequestMapping("boardDownload")
	public void boardDownload(String no, HttpServletResponse response) {
		service.boardDownload(no, response);
	}
	
	@RequestMapping("boardModify")
	public String boardModify(String no, Model model) {
		String sessionId = (String) session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		String path = service.boardModify(no, model);
		return path;
	}
	
	@PostMapping("boardModifyProc")
	public String boardModifyProc(BoardDTO board, RedirectAttributes ra) {
		String sessionId = (String) session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		String msg = service.boardModifyProc(board);
		ra.addFlashAttribute("msg", msg);
		
		if(msg.equals("게시글 수정 성공"))
			return "redirect:boardContent?no="+board.getNo();
		
		return "redirect:boardModify?no="+board.getNo();
	}
	
	@RequestMapping("boardDeleteProc")
	public String boardDeleteProc(String no) {
		String sessionId = (String) session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		
		String msg = service.boardDeleteProc(no);
		if(msg.equals("작성자만 삭제 할 수 있습니다."))
			return "redirect:boardContent?no="+no;
		
		return "redirect:boardForm";
	}
	
}















