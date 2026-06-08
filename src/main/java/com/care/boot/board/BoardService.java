package com.care.boot.board;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;
import org.springframework.util.FileCopyUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;

import com.care.boot.PageService;

import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Service
public class BoardService {
	@Autowired private BoardMapper mapper;
	private String filePath = "/opt/tomcat/tomcat-10/webapps/upload/";
	
	public void boardForm(String cp, Model model) {
		int currentPage = 1;
		try{
			currentPage = Integer.parseInt(cp);
		}catch(Exception e){
			currentPage = 1;
		}
		
		int pageBlock = 3; // 한 페이지에 보일 데이터의 수 
		int end = pageBlock * currentPage; // 테이블에서 가져올 마지막 행번호
		int begin = end - pageBlock + 1; // 테이블에서 가져올 시작 행번호
		
		List<BoardDTO> boards = mapper.boardForm(begin, end);
		int totalCount = mapper.totalCount();
		if(totalCount == 0) {
			return ;
		}
		
		String url = "boardForm?currentPage=";
		String result = PageService.printPage(url, totalCount, pageBlock, currentPage);
		
		model.addAttribute("boards", boards);
		model.addAttribute("result", result);
	}
	
	@Autowired private HttpSession session;
	public String boardWriteProc(MultipartHttpServletRequest multi) {
//		System.out.println("title : " + multi.getParameter("title"));
		String sessionId = (String) session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		
		String title = multi.getParameter("title");
		if(title == null || title.trim().isEmpty()) {
			return "redirect:boardWrite";
		}
		
		BoardDTO board = new BoardDTO();
		board.setTitle(title);
		board.setContent(multi.getParameter("content"));
		board.setId(sessionId);
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
		board.setWriteDate(sdf.format(new Date()));
		board.setFileName("");
		
		MultipartFile file = multi.getFile("upfile");
		if(file.getSize() != 0) { // 클라이언트가 파일을 업로드 했다면
			// 파일의 이름
			sdf = new SimpleDateFormat("yyyyMMddHHmmss-");
			String fileTime = sdf.format(new Date());
			String fileName = file.getOriginalFilename();
			
			String suffix = fileName.substring(fileName.lastIndexOf(".")+1, fileName.length());
			System.out.println("BoardService-boardWriteProc-suffix : " + suffix);
			if(suffix.equalsIgnoreCase("txt") == false)
				return "redirect:boardWrite";
			
			// 파일의 저장 경로
			String fileSaveDirectory = filePath+sessionId;
			File f = new File(fileSaveDirectory);
			if(f.exists() == false) {
//				f.mkdir();
				f.mkdirs();
			}
			
			String fullPath = fileSaveDirectory + "/" + fileTime + fileName;
			board.setFileName(fullPath);
			f = new File(fullPath);
			try {
				file.transferTo(f);
			} catch (Exception e) {
				e.printStackTrace();
				board.setFileName("");
			} 
			
			/*
			 file.transferTo(); //파일을 이동시키는 기능 
			 <input type="file" name="upfile"> 을 사용하여 서버에 파일 데이터가 전달되면
			 웹서버가 임시파일로 저장을 함. 
			 임시파일로 저장된 파일을 개발자가 원하는 경로로 이동시킬 때 file.transferTo()를 사용함.
			 */
		}
		
		// 조회수랑 게시글 번호는 INSERT 명령 시 입력
		mapper.boardWriteProc(board);
		return "redirect:boardForm";
	}
	
	public BoardDTO boardContent(String no) {
		int n = 1;
		try{
			n = Integer.parseInt(no);
		}catch(Exception e){
			return null;
		}
		
		BoardDTO board = mapper.boardContent(n);
		if(board != null) {
			mapper.incrementHits(n);
			board.setHits(board.getHits()+1);
			
			if(board.getFileName() != null) {
				String[] names = board.getFileName().split("/");
				
				for(String name : names)
					System.out.println("BoardService-boardContent name : "+ name);
				/* 	/opt/tomcat/tomcat-10/webapps/upload/user1/20230925140126-pom.xml*/
				
				/* 20230925140126-01-pom-v01.xml */
				String[] fileNames = names[7].split("-", 2);
				for(String fileName : fileNames)
					System.out.println("BoardService-boardContent fileName : "+ fileName);
				
				board.setFileName(fileNames[1]);
			}
		}
		return board;
	}

	public void boardDownload(String no, HttpServletResponse response) {
		int n = 1;
		try{
			n = Integer.parseInt(no);
		}catch(Exception e){
			return ;
		}
		
		String fullPath = mapper.boardDownload(n);
		if(fullPath == null)
			return ;
		
		String[] names = fullPath.split("/");
		String[] fileNames = names[7].split("-", 2);
		
		try {
			File file = new File(fullPath);
			if(file.exists() == false)
				return ;
			
			response.setHeader(
					"Content-Disposition", 
					//attachment;filename=pom.xml
					"attachment;filename=" + URLEncoder.encode(fileNames[1], "UTF-8"));
			
			FileInputStream fis = new FileInputStream(file);
			FileCopyUtils.copy(fis, response.getOutputStream());
			fis.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}

	public String boardModify(String no, Model model) {
		int n = 0;
		try {
			n = Integer.parseInt(no);
		} catch (Exception e) {
			return "redirect:boardForm";
		}
		
		BoardDTO board = mapper.boardContent(n);
		if(board == null)
			return "redirect:boardForm";
		
		if(board.getFileName() != null) {
			String[] names = board.getFileName().split("/");
			String[] fileNames = names[7].split("-", 2);
			board.setFileName(fileNames[1]);
		}
		
		model.addAttribute("board", board);
		return "board/boardModify";
	}

	public String boardModifyProc(BoardDTO board) {
		BoardDTO check = mapper.boardContent(board.getNo());
		if(check == null)
			return "게시글 번호에 문제가 발생했습니다. 다시 시도하세요.";
		
		// 로그인한 아이디와 작성자 아이디가 같은지 확인
		String sessionId = (String)session.getAttribute("id");
		if(check.getId().equals(sessionId) == false)
			return "작성자만 삭제 할 수 있습니다.";
		
		if(board.getTitle() == null || board.getTitle().trim().isEmpty()) {
			return "제목을 입력하세요.";
		}
		
		int result = mapper.boardModifyProc(board);
		if(result == 0)
			return "게시글 수정에 실패했습니다. 다시 시도하세요.";
		
		return "게시글 수정 성공";
	}

	public String boardDeleteProc(String no) {
		// 파일이 존재하면 삭제
		int n = 0;
		try {
			n = Integer.parseInt(no);
		} catch (Exception e) {
			return "게시글 번호에 문제가 발생했습니다. 다시 시도하세요.";
		}
		
		BoardDTO board = mapper.boardContent(n);
		if(board == null)
			return "게시글 번호에 문제가 발생했습니다. 다시 시도하세요.";
		
		// 로그인한 아이디와 작성자 아이디가 같은지 확인
		String sessionId = (String)session.getAttribute("id");
		if(board.getId().equals(sessionId) == false)
			return "작성자만 삭제 할 수 있습니다.";
		
		String fullPath = board.getFileName();
		if(fullPath != null) { // 테이블에 파일의 경로와 이름이 있다면
			File f = new File(fullPath);
			if(f.exists() == true) // 파일 저장소에 파일이 존재한다면
				f.delete();
		}
		
		// 테이블에서 게시글번호와 일치하는 행(row)삭제
		mapper.boardDeleteProc(n);
		return "게시글 삭제 완료";
	}
}











